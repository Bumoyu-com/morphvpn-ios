#!/bin/bash

# 验证脚本 - 检查项目配置是否正确

echo "🔍 验证 MorphVPN iOS 项目配置..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数
PASS=0
FAIL=0
WARN=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARN++))
}

# 1. 检查本地 WireGuardKit 包
echo "1. 检查本地 WireGuardKit 包..."
if [ -d "packages/wireguard-apple" ]; then
    check_pass "本地 WireGuardKit 包存在"
    
    if [ -f "packages/wireguard-apple/Package.swift" ]; then
        check_pass "Package.swift 存在"
    else
        check_fail "Package.swift 不存在"
    fi
    
    if [ -d "packages/wireguard-apple/Sources/WireGuardKit" ]; then
        check_pass "WireGuardKit 源码存在"
    else
        check_fail "WireGuardKit 源码不存在"
    fi
    
    if [ -d "packages/wireguard-apple/Sources/WireGuardKitGo" ]; then
        check_pass "WireGuardKitGo 源码存在"
        
        if [ -f "packages/wireguard-apple/Sources/WireGuardKitGo/Makefile" ]; then
            check_pass "Makefile 存在"
        else
            check_fail "Makefile 不存在"
        fi
    else
        check_fail "WireGuardKitGo 源码不存在"
    fi
else
    check_fail "本地 WireGuardKit 包不存在"
fi

echo ""

# 2. 检查 project.pbxproj 配置
echo "2. 检查 project.pbxproj 配置..."
if [ -f "ios/App/App.xcodeproj/project.pbxproj" ]; then
    check_pass "project.pbxproj 存在"
    
    # 检查包路径
    if grep -q 'relativePath = "../../packages/wireguard-apple"' ios/App/App.xcodeproj/project.pbxproj; then
        check_pass "Swift Package 路径已更新为本地包"
    else
        if grep -q 'Downloads/wireguard-apple' ios/App/App.xcodeproj/project.pbxproj; then
            check_fail "Swift Package 仍指向 Downloads 目录"
        else
            check_warn "无法确认 Swift Package 路径"
        fi
    fi
    
    # 检查构建目录
    if grep -q 'buildWorkingDirectory = "${SRCROOT}/../../packages/wireguard-apple/Sources/WireGuardKitGo"' ios/App/App.xcodeproj/project.pbxproj; then
        check_pass "WireGuardGoBridgeiOS 构建目录已更新"
    else
        if grep -q 'SourcePackages/checkouts/wireguard-apple' ios/App/App.xcodeproj/project.pbxproj; then
            check_fail "WireGuardGoBridgeiOS 仍指向 SourcePackages"
        else
            check_warn "无法确认 WireGuardGoBridgeiOS 构建目录"
        fi
    fi
    
    # 检查 objectVersion
    OBJECT_VERSION=$(grep "objectVersion = " ios/App/App.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \([0-9]*\);/\1/')
    if [ "$OBJECT_VERSION" = "70" ]; then
        check_warn "objectVersion = 70 (需要 CocoaPods 1.15.0+)"
    else
        check_pass "objectVersion = $OBJECT_VERSION"
    fi
else
    check_fail "project.pbxproj 不存在"
fi

echo ""

# 3. 检查文档
echo "3. 检查文档..."
if [ -f "SETUP_GUIDE.md" ]; then
    check_pass "SETUP_GUIDE.md 存在"
else
    check_fail "SETUP_GUIDE.md 不存在"
fi

if [ -f "BUILD_FIXES.md" ]; then
    check_pass "BUILD_FIXES.md 存在"
else
    check_fail "BUILD_FIXES.md 不存在"
fi

if [ -f "QUICK_START.md" ]; then
    check_pass "QUICK_START.md 存在"
else
    check_fail "QUICK_START.md 不存在"
fi

echo ""

# 4. 检查系统工具
echo "4. 检查系统工具..."
if command -v make &> /dev/null; then
    MAKE_VERSION=$(make --version | head -1)
    check_pass "make 已安装: $MAKE_VERSION"
else
    check_fail "make 未安装"
fi

if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    check_pass "CocoaPods 已安装: $POD_VERSION"
    
    # 检查版本
    if [ "$(printf '%s\n' "1.15.0" "$POD_VERSION" | sort -V | head -n1)" = "1.15.0" ]; then
        check_pass "CocoaPods 版本 >= 1.15.0"
    else
        check_warn "CocoaPods 版本 < 1.15.0，建议更新"
    fi
else
    check_warn "CocoaPods 未安装（需要运行 pod install）"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    check_pass "npm 已安装: $NPM_VERSION"
else
    check_fail "npm 未安装"
fi

echo ""

# 5. 检查 Podfile
echo "5. 检查 Podfile..."
if [ -f "ios/App/Podfile" ]; then
    check_pass "Podfile 存在"
    
    if grep -q "MorphvpnCapacitorWireguard" ios/App/Podfile; then
        check_pass "Podfile 包含 WireGuard 插件"
    else
        check_warn "Podfile 未包含 WireGuard 插件"
    fi
else
    check_fail "Podfile 不存在"
fi

echo ""

# 总结
echo "================================"
echo "验证结果总结:"
echo "================================"
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${YELLOW}警告: $WARN${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ 项目配置验证通过！${NC}"
    echo ""
    echo "下一步："
    echo "1. 如果 CocoaPods < 1.15.0，运行: sudo gem install cocoapods"
    echo "2. 清理缓存: rm -rf ~/Library/Developer/Xcode/DerivedData"
    echo "3. 安装依赖: cd ios/App && pod install"
    echo "4. 打开 Xcode: npx cap open ios"
    echo ""
    echo "详细步骤请查看 QUICK_START.md"
    exit 0
else
    echo -e "${RED}❌ 项目配置存在问题，请检查失败项${NC}"
    echo ""
    echo "请查看 BUILD_FIXES.md 获取详细的解决方案"
    exit 1
fi

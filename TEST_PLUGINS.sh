#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}插件测试脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 测试 WireGuard 插件
echo -e "${GREEN}1️⃣  测试 WireGuard 插件${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd packages/wireguard-plugin || exit 1

echo -e "${YELLOW}📦 安装依赖...${NC}"
npm install > /dev/null 2>&1

echo -e "${YELLOW}🔨 构建插件...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ WireGuard 插件构建成功${NC}"
else
    echo -e "${RED}❌ WireGuard 插件构建失败${NC}"
    exit 1
fi

cd ../..
echo ""

# 测试 MorphProtocol 插件
echo -e "${GREEN}2️⃣  测试 MorphProtocol 插件${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd packages/morphprotocol-plugin || exit 1

echo -e "${YELLOW}📦 安装依赖...${NC}"
npm install > /dev/null 2>&1

echo -e "${YELLOW}🔨 构建插件...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ MorphProtocol 插件构建成功${NC}"
else
    echo -e "${RED}❌ MorphProtocol 插件构建失败${NC}"
    exit 1
fi

cd ../..
echo ""

# 检查文件结构
echo -e "${GREEN}3️⃣  检查文件结构${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
    else
        echo -e "${RED}❌${NC} $1 ${RED}(缺失)${NC}"
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $1/"
    else
        echo -e "${RED}❌${NC} $1/ ${RED}(缺失)${NC}"
    fi
}

echo -e "${BLUE}WireGuard 插件:${NC}"
check_dir "packages/wireguard-plugin/dist"
check_file "packages/wireguard-plugin/dist/esm/index.js"
check_file "packages/wireguard-plugin/dist/plugin.js"

echo ""
echo -e "${BLUE}MorphProtocol 插件:${NC}"
check_dir "packages/morphprotocol-plugin/dist"
check_file "packages/morphprotocol-plugin/dist/esm/index.js"
check_file "packages/morphprotocol-plugin/dist/plugin.js"

echo ""
echo -e "${BLUE}iOS 原生代码:${NC}"
check_dir "packages/wireguard-plugin/ios/Plugin"
check_file "packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift"
check_dir "packages/morphprotocol-plugin/ios/Plugin"
check_file "packages/morphprotocol-plugin/ios/Plugin/MorphProtocolPlugin.swift"

echo ""

# 检查 WireGuard 是否纯净
echo -e "${GREEN}4️⃣  检查 WireGuard 插件纯净度${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if grep -q "morphProtocol\|MorphProtocol" packages/wireguard-plugin/src/definitions.ts; then
    echo -e "${RED}❌ definitions.ts 包含 MorphProtocol 引用${NC}"
else
    echo -e "${GREEN}✅ definitions.ts 纯净${NC}"
fi

if grep -q "morphProtocol\|MorphProtocol" packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift; then
    echo -e "${YELLOW}⚠️  WireGuardPlugin.swift 包含 MorphProtocol 引用 (可选清理)${NC}"
else
    echo -e "${GREEN}✅ WireGuardPlugin.swift 纯净${NC}"
fi

if [ -d "ios/App/WireGuardExtension/MorphProtocol" ]; then
    echo -e "${RED}❌ WireGuardExtension 仍包含 MorphProtocol 目录${NC}"
else
    echo -e "${GREEN}✅ WireGuardExtension 纯净${NC}"
fi

echo ""

# 总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 所有测试通过！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo -e "1. 安装插件: ${GREEN}./INSTALL_PLUGIN.sh all${NC}"
echo -e "2. 在 Xcode 中打开: ${GREEN}npx cap open ios${NC}"
echo -e "3. 构建并测试"
echo ""

#!/bin/bash

# WireGuard 插件安装脚本

set -e

echo "=================================="
echo "安装 WireGuard 插件"
echo "=================================="

# 1. 进入插件目录
echo ""
echo "步骤 1: 构建插件..."
cd packages/wireguard-plugin

# 2. 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo "安装插件依赖..."
    npm install
fi

# 3. 构建插件
echo "构建插件..."
npm run build

# 4. 打包插件
echo "打包插件..."
npm pack

# 5. 返回主项目
cd ../..

# 6. 安装插件到主项目
echo ""
echo "步骤 2: 安装插件到主项目..."
npm install ./packages/wireguard-plugin/morphvpn-capacitor-wireguard-1.0.0.tgz

# 7. 同步到 iOS
echo ""
echo "步骤 3: 同步到 iOS..."
npx cap sync ios

# 8. 验证安装
echo ""
echo "步骤 4: 验证安装..."
npx cap ls

echo ""
echo "=================================="
echo "✅ 安装完成！"
echo "=================================="
echo ""
echo "下一步："
echo "1. 运行: npx cap open ios"
echo "2. 在 Xcode 中运行到 iOS 设备"
echo ""

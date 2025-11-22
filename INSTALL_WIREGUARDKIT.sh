#!/bin/bash

# WireGuardKit 安装脚本

set -e

echo "=================================="
echo "安装 WireGuardKit"
echo "=================================="

cd ios/App

echo ""
echo "步骤 1: 清理旧的 Pods..."
rm -rf Pods Podfile.lock

echo ""
echo "步骤 2: 更新 CocoaPods 仓库..."
pod repo update

echo ""
echo "步骤 3: 安装依赖..."
pod install

echo ""
echo "=================================="
echo "✅ 安装完成！"
echo "=================================="
echo ""
echo "下一步："
echo "1. 运行: npx cap open ios"
echo "2. 确保打开的是 App.xcworkspace（不是 .xcodeproj）"
echo "3. 替换 PacketTunnelProvider.swift 的内容"
echo "4. 配置 App Groups"
echo "5. 构建并运行"
echo ""

cd ../..

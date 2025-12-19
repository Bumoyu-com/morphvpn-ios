#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    echo -e "${BLUE}使用方法:${NC}"
    echo -e "  $0 [plugin_name]"
    echo -e ""
    echo -e "${BLUE}可用插件:${NC}"
    echo -e "  ${GREEN}wireguard${NC}      - WireGuard VPN 插件"
    echo -e "  ${GREEN}morphprotocol${NC}  - MorphProtocol 混淆插件"
    echo -e "  ${GREEN}all${NC}            - 安装所有插件"
    echo -e ""
    echo -e "${BLUE}示例:${NC}"
    echo -e "  $0 wireguard"
    echo -e "  $0 morphprotocol"
    echo -e "  $0 all"
}

install_plugin() {
    local plugin_name=$1
    local plugin_dir=$2
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}开始安装 ${plugin_name} 插件...${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$plugin_dir" ]; then
        echo -e "${RED}❌ 错误: 插件目录不存在: $plugin_dir${NC}"
        return 1
    fi
    
    cd "$plugin_dir" || return 1
    
    echo -e "${YELLOW}📦 安装插件依赖...${NC}"
    npm install > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo -e "${YELLOW}🔨 构建插件...${NC}"
    npm run build
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 构建失败${NC}"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
    
    echo -e "${YELLOW}📥 安装插件到主项目...${NC}"
    npm install "file:$plugin_dir" --legacy-peer-deps
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 插件安装失败${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ ${plugin_name} 插件安装完成！${NC}"
    return 0
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local plugin=$1
    local success=true
    
    case $plugin in
        wireguard)
            install_plugin "WireGuard" "packages/wireguard-plugin"
            success=$?
            ;;
        morphprotocol)
            install_plugin "MorphProtocol" "packages/morphprotocol-plugin"
            success=$?
            ;;
        all)
            echo -e "${BLUE}安装所有插件...${NC}"
            echo ""
            install_plugin "WireGuard" "packages/wireguard-plugin"
            local wireguard_result=$?
            echo ""
            install_plugin "MorphProtocol" "packages/morphprotocol-plugin"
            local morph_result=$?
            
            if [ $wireguard_result -eq 0 ] && [ $morph_result -eq 0 ]; then
                success=0
            else
                success=1
            fi
            ;;
        *)
            echo -e "${RED}❌ 未知插件: $plugin${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    if [ $success -eq 0 ]; then
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}📱 同步到 iOS...${NC}"
        npx cap sync ios
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 所有操作完成！${NC}"
            echo ""
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}下一步：${NC}"
            echo -e "1. 在 Xcode 中打开项目: ${GREEN}npx cap open ios${NC}"
            echo -e "2. 清理构建文件夹: ${GREEN}Product → Clean Build Folder (⇧⌘K)${NC}"
            echo -e "3. 构建项目: ${GREEN}Product → Build (⌘B)${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        else
            echo -e "${RED}❌ iOS 同步失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 插件安装失败${NC}"
        exit 1
    fi
}

main "$@"

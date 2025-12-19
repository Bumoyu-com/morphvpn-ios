# 🧪 MorphProtocol 测试指南

## 概述

本指南将帮助你在 Mac 上启动 MorphProtocol 服务端，并在 iPhone 上测试客户端连接。

---

## 📋 前置条件

### 硬件要求
- ✅ Mac（运行服务端）
- ✅ iPhone（运行客户端）
- ✅ 两者连接到同一个 Wi-Fi 网络

### 软件要求
- ✅ Mac 上已安装 Node.js
- ✅ iPhone 上已安装本项目的 iOS 应用
- ✅ morphProtocol 服务端项目已克隆

---

## 第一步：配置服务端

### 1. 获取 Mac 的本地 IP 地址

在 Mac 终端运行：
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

输出示例：
```
inet 192.168.1.100  netmask 255.255.255.0  broadcast 192.168.1.255
```

记下这个 IP 地址（例如：`192.168.1.100`）

### 2. 创建 .env 配置文件

在 morphProtocol 项目根目录创建 `.env` 文件：

```bash
cd /path/to/morphProtocol
cp .env.example .env
```

### 3. 编辑 .env 文件

```bash
# 服务器配置
HOST_NAME=mac-server
HOST_IP=0.0.0.0                    # 监听所有网络接口
HANDSHAKE_PORT_UDP=12301           # 客户端连接端口

# WireGuard 配置（如果不使用 WireGuard，可以保持默认）
LOCAL_WG_ADDRESS=127.0.0.1
LOCAL_WG_PORT=51820

# 安全配置
PASSWORD=test123                   # 简单密码用于测试

# 超时配置（毫秒）
TIMEOUT_DURATION=1200000           # 20分钟
TRAFFIC_INTERVAL=600000            # 10分钟
HEARTBEAT_INTERVAL=120000          # 2分钟

# 客户端默认配置
MAX_RETRIES=5
OBFUSCATION_LAYER=3                # 混淆层数（1-4）
PADDING_LENGTH=8                   # 填充长度（1-16）

# API 配置（测试时可以注释掉或使用假地址）
# SUB_TRAFFIC_URL=https://api.example.com/traffic/subtract
# ADD_CLIENTNUM_URL=https://api.example.com/clients/add
# SUB_CLIENTNUM_URL=https://api.example.com/clients/subtract
# UPDATE_SERVERINFO_URL=https://api.example.com/servers/update
# API_AUTH_TOKEN=your_api_token_here

# 日志级别
LOG_LEVEL=1                        # 1=详细日志
```

### 4. 启动服务端

```bash
cd /path/to/morphProtocol
npm install                        # 首次运行需要安装依赖
npm run server
```

### 5. 记录加密密钥

服务端启动后会显示加密密钥，类似：

```
🔐 Encryption Key: XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS
```

**重要：** 复制这个密钥，客户端需要使用它！

---

## 第二步：配置客户端（iPhone）

### 参数对应关系

| 服务端 .env 参数 | 客户端 React 页面字段 | 说明 |
|-----------------|---------------------|------|
| `HOST_IP` (Mac IP) | **服务器** (host) | Mac 的本地 IP，如 `192.168.1.100` |
| `HANDSHAKE_PORT_UDP` | **端口** (port) | 默认 `12301` |
| 服务端启动时显示的密钥 | **加密密钥** (encryptionKey) | 格式：`base64key:base64iv` |
| `OBFUSCATION_LAYER` | **混淆层数** (obfuscationLayer) | 1-4，推荐 `3` |
| `PADDING_LENGTH` | **填充长度** (paddingLength) | 1-16，默认 `8` |
| - | **协议模板** (templateType) | 0=无, 1=QUIC, 2=KCP, 3=游戏 |

### 在 iPhone 上配置

1. **打开应用**
   - 在 iPhone 上启动 morphvpn-ios 应用

2. **导航到测试页面**
   - 找到 "MorphProtocol 独立测试" 页面
   - 或使用 `TestMorphProtocol` 组件

3. **填写连接参数**

   ```
   服务器: 192.168.1.100          # 你的 Mac IP
   端口: 12301                     # 服务端的 HANDSHAKE_PORT_UDP
   加密密钥: XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS
   混淆层数: 3层（推荐）
   协议模板: QUIC（推荐）
   ```

4. **点击连接**
   - 点击 "连接" 按钮
   - 观察状态变化

---

## 第三步：测试连接

### 在服务端观察日志

服务端应该显示：

```
🤝 Handshake received from 192.168.1.xxx:xxxxx
✅ Client connected: user_xxx
📊 Active tunnels: 1
```

### 在客户端测试

1. **检查状态**
   - 状态应该从 `disconnected` 变为 `connected`

2. **发送测试数据**
   - 点击 "发送测试" 按钮
   - 应该看到 "测试数据已发送" 消息

3. **查看日志**
   - 在 Xcode 控制台查看详细日志
   - 搜索 `🔌 MorphProtocol` 关键字

---

## 参数详解

### 服务端参数

#### HOST_IP
- **值**: `0.0.0.0`
- **说明**: 监听所有网络接口，允许从任何 IP 连接
- **注意**: 不要设置为 `127.0.0.1`，否则只能本地连接

#### HANDSHAKE_PORT_UDP
- **值**: `12301`（默认）
- **说明**: 客户端连接的端口
- **注意**: 确保防火墙允许此端口

#### OBFUSCATION_LAYER
- **值**: `1-4`
- **推荐**: `3`
- **说明**: 混淆层数，越多越安全但性能略低

#### PADDING_LENGTH
- **值**: `1-16`
- **默认**: `8`
- **说明**: 随机填充长度，防止流量分析

### 客户端参数

#### host (服务器)
- **格式**: IP 地址
- **示例**: `192.168.1.100`
- **获取方式**: 在 Mac 上运行 `ifconfig`

#### port (端口)
- **值**: 与服务端 `HANDSHAKE_PORT_UDP` 相同
- **默认**: `12301`

#### encryptionKey (加密密钥)
- **格式**: `base64key:base64iv`
- **示例**: `XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS`
- **获取方式**: 从服务端启动日志中复制

#### obfuscationLayer (混淆层数)
- **值**: `1-4`
- **推荐**: `3`
- **说明**: 必须与服务端配置匹配

#### paddingLength (填充长度)
- **值**: `1-16`
- **默认**: `8`
- **说明**: 随机填充，增加安全性

#### templateType (协议模板)
- **0**: 无模板（原始数据）
- **1**: QUIC 模板（推荐，伪装成 QUIC 流量）
- **2**: KCP 模板（伪装成 KCP 流量）
- **3**: 游戏协议模板（伪装成游戏流量）

---

## 常见问题

### 1. 连接失败：无法连接到服务器

**可能原因：**
- Mac 和 iPhone 不在同一个 Wi-Fi
- Mac IP 地址错误
- 防火墙阻止了端口

**解决方案：**
```bash
# 在 Mac 上检查 IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# 检查防火墙（macOS）
sudo pfctl -s rules | grep 12301

# 临时关闭防火墙测试
sudo pfctl -d
```

### 2. 连接成功但无法发送数据

**可能原因：**
- 加密密钥不匹配
- 混淆层数配置不一致

**解决方案：**
- 确保客户端使用服务端显示的加密密钥
- 确保混淆层数相同

### 3. 服务端显示 "Handshake timeout"

**可能原因：**
- 客户端发送的握手包被丢弃
- 网络延迟过高

**解决方案：**
- 增加 `TIMEOUT_DURATION` 值
- 检查网络质量

### 4. 数据接收不完整

**可能原因：**
- UDP 包丢失
- 混淆/解混淆错误

**解决方案：**
- 启用服务端的 `DEBUG_MODE=true`
- 检查日志中的错误信息

---

## 调试技巧

### 服务端调试

1. **启用详细日志**
   ```bash
   LOG_LEVEL=1
   ```

2. **启用调试模式**
   ```bash
   DEBUG_MODE=true
   ```

3. **查看实时日志**
   ```bash
   npm run server | tee server.log
   ```

### 客户端调试

1. **在 Xcode 中查看日志**
   - View → Debug Area → Show Debug Area (⇧⌘Y)
   - 搜索关键字：`MorphProtocol`, `❌`, `✅`

2. **使用断点**
   - 在 `MorphProtocolPlugin.swift` 中设置断点
   - 检查参数值

3. **检查网络流量**
   ```bash
   # 在 Mac 上监听 UDP 流量
   sudo tcpdump -i any -n udp port 12301
   ```

---

## 测试流程

### 完整测试步骤

1. **启动服务端**
   ```bash
   cd /path/to/morphProtocol
   npm run server
   ```

2. **记录信息**
   - Mac IP: `192.168.1.100`
   - 端口: `12301`
   - 加密密钥: `XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS`

3. **配置客户端**
   - 在 iPhone 上打开应用
   - 填写服务器信息
   - 选择混淆层数和协议模板

4. **连接测试**
   - 点击 "连接"
   - 等待状态变为 `connected`

5. **数据测试**
   - 点击 "发送测试"
   - 检查服务端日志
   - 检查客户端接收数据

6. **断开测试**
   - 点击 "断开"
   - 检查状态变为 `disconnected`

---

## 性能测试

### 测试不同配置

1. **测试混淆层数**
   ```
   Layer 1: 最快，安全性最低
   Layer 2: 较快，安全性中等
   Layer 3: 平衡（推荐）
   Layer 4: 最安全，性能略低
   ```

2. **测试协议模板**
   ```
   None (0): 无伪装
   QUIC (1): 伪装成 QUIC（推荐）
   KCP (2): 伪装成 KCP
   Gaming (3): 伪装成游戏流量
   ```

3. **测试填充长度**
   ```
   1-4: 最小填充
   5-8: 推荐范围
   9-16: 最大填充
   ```

---

## 安全建议

### 生产环境配置

1. **使用强密码**
   ```bash
   PASSWORD=$(openssl rand -base64 32)
   ```

2. **限制连接 IP**
   ```bash
   # 只允许特定 IP 连接
   HOST_IP=192.168.1.100
   ```

3. **启用 API 认证**
   ```bash
   API_AUTH_TOKEN=$(openssl rand -hex 32)
   ```

4. **定期更换密钥**
   - 重启服务端会生成新密钥
   - 客户端需要更新密钥

---

## 参考资源

- [morphProtocol GitHub](https://github.com/StarnesG/morphProtocol)
- [服务端 README](https://github.com/StarnesG/morphProtocol/blob/main/README.md)
- [iOS 实现指南](https://github.com/StarnesG/morphProtocol/blob/main/IOS_IMPLEMENTATION_GUIDE.md)

---

## 检查清单

测试前：
- [ ] Mac 和 iPhone 在同一 Wi-Fi
- [ ] 已获取 Mac 的本地 IP
- [ ] 已创建并配置 .env 文件
- [ ] 已安装服务端依赖

测试中：
- [ ] 服务端成功启动
- [ ] 已记录加密密钥
- [ ] 客户端配置正确
- [ ] 防火墙允许端口

测试后：
- [ ] 连接成功
- [ ] 数据发送成功
- [ ] 数据接收成功
- [ ] 断开连接成功

---

**最后更新**: 2024-12-19
**状态**: ✅ 就绪

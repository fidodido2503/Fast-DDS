# Fast-DDS 使用指南 (How to Use Fast-DDS)

本指南将帮助您学习如何使用 eProsima Fast-DDS，这是一个高性能的 DDS (Data Distribution Service) 中间件实现。

## 目录
1. [什么是 Fast-DDS](#什么是-fast-dds)
2. [安装和构建](#安装和构建)
3. [基本概念](#基本概念)
4. [快速开始 - Hello World 示例](#快速开始---hello-world-示例)
5. [运行示例](#运行示例)
6. [高级用法](#高级用法)
7. [更多示例](#更多示例)
8. [官方文档和资源](#官方文档和资源)

## 什么是 Fast-DDS

eProsima Fast-DDS 是一个基于 C++ 的 DDS (Data Distribution Service) 标准实现，它提供：

- **实时发布-订阅通信**：支持可靠和尽力而为的通信策略
- **自动发现**：新应用程序会被网络中的其他成员自动发现
- **模块化和可扩展性**：支持复杂和简单设备的持续增长
- **可配置的网络行为**：可选择最佳协议和传输层组合
- **双层 API**：
  - 高层 Publisher-Subscriber API (DDS)
  - 低层 Writer-Reader API (RTPS)

**应用场景**：
- 机器人技术（ROS 2 的默认中间件）
- 工业自动化
- 实时系统
- 分布式系统通信

## 安装和构建

### 依赖项

在构建 Fast-DDS 之前，您需要安装以下依赖项：

```bash
# Ubuntu/Debian 系统
sudo apt update
sudo apt install -y \
    cmake \
    g++ \
    python3-pip \
    wget \
    git \
    libasio-dev \
    libtinyxml2-dev \
    libssl-dev

# 安装 colcon (可选，用于 ROS 2 生态系统)
pip3 install colcon-common-extensions
```

### 从源码构建

1. **克隆仓库和依赖项**：
```bash
# 创建工作空间
mkdir ~/fastdds_ws && cd ~/fastdds_ws
git clone https://github.com/eProsima/Fast-DDS.git
cd Fast-DDS

# 获取依赖项的源码（推荐方法）
mkdir src && cd src
git clone https://github.com/eProsima/Fast-CDR.git
git clone https://github.com/eProsima/foonathan_memory_vendor.git
```

2. **构建 Fast-CDR（必需依赖）**：
```bash
cd Fast-CDR
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
cd ../..
```

3. **构建 foonathan_memory（必需依赖）**：
```bash
cd foonathan_memory_vendor
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
cd ../..
```

4. **构建 Fast-DDS**：
```bash
cd ..
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig
```

### 验证安装

```bash
# 检查库是否正确安装
ldconfig -p | grep fastdds
ldconfig -p | grep fastcdr
```

## 基本概念

### DDS 核心概念

1. **Domain Participant**：DDS 域的参与者，管理其他 DDS 实体
2. **Publisher**：发布者，管理一个或多个 DataWriter
3. **Subscriber**：订阅者，管理一个或多个 DataReader
4. **DataWriter**：数据写入器，发布特定类型的数据
5. **DataReader**：数据读取器，接收特定类型的数据
6. **Topic**：主题，定义数据类型和名称

### 数据流模式

```
发布者应用程序                    订阅者应用程序
┌─────────────────────┐        ┌─────────────────────┐
│  Domain Participant │        │  Domain Participant │
│  ┌─────────────────┐│        │  ┌─────────────────┐│
│  │   Publisher     ││        │  │   Subscriber    ││
│  │  ┌─────────────┐││        │  │  ┌─────────────┐││
│  │  │ DataWriter  │││───────►│  │  │ DataReader  │││
│  │  └─────────────┘││        │  │  └─────────────┘││
│  └─────────────────┘│        │  └─────────────────┘│
└─────────────────────┘        └─────────────────────┘
```

## 快速开始 - Hello World 示例

Hello World 示例展示了 Fast-DDS 的基本用法，包含一个发布者和一个订阅者。

### 示例结构

```
examples/cpp/hello_world/
├── Application.cpp          # 应用程序基类
├── Application.hpp
├── CLIParser.hpp           # 命令行解析
├── HelloWorld.idl          # IDL 数据类型定义
├── HelloWorld.hpp          # 生成的数据类型
├── HelloWorldPubSubTypes.* # 生成的序列化类型
├── ListenerSubscriberApp.* # 监听器模式的订阅者
├── PublisherApp.*          # 发布者应用
├── WaitsetSubscriberApp.*  # 等待集模式的订阅者
├── main.cpp               # 主程序入口
├── hello_world_profile.xml # XML 配置文件
└── README.md              # 详细说明
```

### 数据类型定义

示例使用简单的 `HelloWorld` 消息类型：

```cpp
// HelloWorld.idl 的内容
struct HelloWorld
{
    unsigned long index;
    string message;
};
```

### 发布者示例代码解析

发布者创建以下 DDS 实体：
1. Domain Participant
2. Publisher  
3. Topic
4. DataWriter

主要功能：
- 周期性发送 HelloWorld 消息
- 每个消息包含递增的索引和 "Hello world" 文本
- 等待订阅者连接后开始发送

### 订阅者示例代码解析

订阅者支持两种接收模式：

1. **监听器模式（默认）**：
   - 使用回调函数处理新数据
   - 当有新数据到达时自动触发

2. **等待集模式**：
   - 使用专用线程等待状态变化
   - 通过 `--waitset` 参数启用

## 运行示例

### 构建 Hello World 示例

```bash
cd examples/cpp/hello_world
mkdir build && cd build
cmake ..
make
```

### 运行发布者

在第一个终端中：
```bash
./hello_world publisher
```

预期输出：
```
Publisher running. Please press Ctrl+C to stop the Publisher at any time.
Publisher matched.
Message: 'Hello world' with index: '1' SENT
Message: 'Hello world' with index: '2' SENT
Message: 'Hello world' with index: '3' SENT
...
```

### 运行订阅者

在第二个终端中：
```bash
./hello_world subscriber
```

预期输出：
```
Subscriber running. Please press Ctrl+C to stop the Subscriber at any time.
Subscriber matched.
Message: 'Hello world' with index: '1' RECEIVED
Message: 'Hello world' with index: '2' RECEIVED
Message: 'Hello world' with index: '3' RECEIVED
...
```

### 使用等待集模式

```bash
./hello_world subscriber --waitset
```

### 命令行选项

查看所有可用选项：
```bash
./hello_world --help
```

常用选项：
- `--samples <数量>`：发送/接收指定数量的样本后停止
- `--domain <ID>`：指定 DDS 域 ID
- `--interval <毫秒>`：设置发布间隔

## 高级用法

### XML 配置文件

Fast-DDS 支持通过 XML 文件配置 QoS 策略：

```bash
export FASTDDS_DEFAULT_PROFILES_FILE=hello_world_profile.xml
./hello_world publisher
```

XML 配置示例包含：
- **可靠性设置**：避免样本丢失
- **持久性设置**：支持晚加入的订阅者接收之前的样本
- **历史设置**：保留一定数量的历史样本

### QoS (Quality of Service) 策略

Fast-DDS 支持多种 QoS 策略：

1. **可靠性 (Reliability)**：
   - `RELIABLE`：保证数据传递
   - `BEST_EFFORT`：尽力传递，不保证

2. **持久性 (Durability)**：
   - `VOLATILE`：数据不持久化
   - `TRANSIENT_LOCAL`：本地持久化

3. **历史 (History)**：
   - `KEEP_LAST`：保留最新的 N 个样本
   - `KEEP_ALL`：保留所有样本

## 更多示例

仓库中包含多个示例，展示不同功能：

### 1. 发现服务器 (Discovery Server)
```bash
cd examples/cpp/discovery_server
```
- 演示集中式发现机制
- 减少网络流量
- 适用于大规模部署

### 2. 内容过滤 (Content Filter)
```bash
cd examples/cpp/content_filter
```
- 基于内容过滤消息
- SQL 风格的过滤表达式
- 减少不必要的数据传输

### 3. 安全通信 (Security)
```bash
cd examples/cpp/security
```
- TLS/DTLS 加密
- 身份验证和授权
- 数据完整性保护

### 4. 自定义载荷池 (Custom Payload Pool)
```bash
cd examples/cpp/custom_payload_pool
```
- 自定义内存管理
- 优化大数据传输
- 减少内存复制

### 5. 静态 EDP 发现 (Static EDP Discovery)
```bash
cd examples/cpp/static_edp_discovery
```
- 预配置的端点发现
- 无需动态发现过程
- 适用于确定性环境

## 官方文档和资源

### 官方文档
- [Fast-DDS 在线文档](https://fast-dds.docs.eprosima.com)
- [安装指南](https://fast-dds.docs.eprosima.com/en/latest/installation/binaries/binaries_linux.html)
- [用户手册](https://fast-dds.docs.eprosima.com/en/latest/fastdds/getting_started/getting_started.html)
- [API 参考](https://fast-dds.docs.eprosima.com/en/latest/fastdds/api_reference/api_reference.html)

### 工具和实用程序
- [Fast-DDS-Gen](https://fast-dds.docs.eprosima.com/en/latest/fastddsgen/introduction/introduction.html)：IDL 代码生成器
- [Fast-DDS CLI](https://fast-dds.docs.eprosima.com/en/latest/fastddscli/cli/cli.html)：命令行工具
- [Shapes Demo](https://eprosima-shapes-demo.readthedocs.io/)：图形化演示应用
- [Fast-DDS Monitor](https://fast-dds-monitor.readthedocs.io/)：监控工具

### 社区和支持
- [GitHub 仓库](https://github.com/eProsima/Fast-DDS)
- [eProsima 官网](https://eprosima.com/)
- [ROS 2 文档](https://docs.ros.org/en/rolling/Concepts/About-Middleware-Implementations.html)

### Docker 镜像
eProsima 提供了预构建的 Docker 镜像，包含：
- Fast-DDS 库和示例
- Shapes Demo
- Fast-DDS Monitor
- 完整的开发环境

```bash
# 下载并运行 Docker 镜像
docker pull eprosima/fast-dds:latest
docker run -it --rm eprosima/fast-dds:latest
```

---

## 故障排除

### 常见问题

1. **构建失败 - 缺少依赖项**：
   ```bash
   # 确保所有依赖项都已安装
   sudo apt install cmake g++ libasio-dev libtinyxml2-dev libssl-dev
   ```

2. **运行时找不到库**：
   ```bash
   # 更新库缓存
   sudo ldconfig
   # 检查 LD_LIBRARY_PATH
   export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
   ```

3. **防火墙问题**：
   ```bash
   # Fast-DDS 使用 UDP 多播，确保防火墙允许相关端口
   sudo ufw allow 7400:7500/udp
   ```

4. **多播不工作**：
   ```bash
   # 启用环回多播
   sudo route add -net 224.0.0.0 netmask 240.0.0.0 dev lo
   ```

### 调试技巧

1. **启用详细日志**：
   ```cpp
   eprosima::fastdds::dds::Log::SetVerbosity(eprosima::fastdds::dds::Log::Kind::Info);
   ```

2. **使用 XML 配置文件调试**：
   ```xml
   <log>
       <use_default>TRUE</use_default>
       <consumer>
           <class>StdoutConsumer</class>
       </consumer>
   </log>
   ```

3. **网络诊断**：
   ```bash
   # 检查多播流量
   tcpdump -i any multicast
   # 检查 Fast-DDS 端口
   netstat -an | grep 7400
   ```

---

这个指南为您提供了使用 Fast-DDS 的完整入门知识。建议从 Hello World 示例开始，然后逐步探索更高级的功能和示例。
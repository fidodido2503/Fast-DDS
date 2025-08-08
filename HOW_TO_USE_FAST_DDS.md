# Fast-DDS Learning Guide / Fast-DDS 学习指南

*[中文版本请查看：如何使用Fast-DDS指南.md](./如何使用Fast-DDS指南.md)*

This guide will help you learn how to use eProsima Fast-DDS, a high-performance DDS (Data Distribution Service) middleware implementation.

## Table of Contents
1. [What is Fast-DDS](#what-is-fast-dds)
2. [Installation and Building](#installation-and-building)
3. [Basic Concepts](#basic-concepts)
4. [Quick Start - Hello World Example](#quick-start---hello-world-example)
5. [Running Examples](#running-examples)
6. [Advanced Usage](#advanced-usage)
7. [More Examples](#more-examples)
8. [Official Documentation and Resources](#official-documentation-and-resources)

## What is Fast-DDS

eProsima Fast-DDS is a C++ implementation of the DDS (Data Distribution Service) standard that provides:

- **Real-time Publish-Subscribe Communication**: Supports both reliable and best-effort communication policies
- **Automatic Discovery**: New applications are automatically discovered by other network members
- **Modularity and Scalability**: Supports continuous growth with complex and simple devices
- **Configurable Network Behavior**: Choose the best protocol and transport layer combination
- **Two-Layer API**:
  - High-level Publisher-Subscriber API (DDS)
  - Low-level Writer-Reader API (RTPS)

**Use Cases**:
- Robotics (Default middleware for ROS 2)
- Industrial Automation
- Real-time Systems
- Distributed System Communication

## Installation and Building

### Quick Start Script

We've provided a quick start script to help you get Fast-DDS up and running quickly:

```bash
# Make the script executable
chmod +x quick_start.sh

# Install dependencies and build everything
./quick_start.sh --install-deps --demo

# For local installation (no sudo required)
./quick_start.sh --install-deps --local-install --demo

# Clean build files
./quick_start.sh --clean

# Show help
./quick_start.sh --help
```

### Manual Installation

#### Dependencies

Before building Fast-DDS, install the following dependencies:

```bash
# Ubuntu/Debian systems
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

# Install colcon (optional, for ROS 2 ecosystem)
pip3 install colcon-common-extensions
```

#### Building from Source

1. **Clone repository and dependencies**:
```bash
# Create workspace
mkdir ~/fastdds_ws && cd ~/fastdds_ws
git clone https://github.com/eProsima/Fast-DDS.git
cd Fast-DDS

# Get dependency sources (recommended method)
mkdir deps && cd deps
git clone https://github.com/eProsima/Fast-CDR.git
git clone https://github.com/eProsima/foonathan_memory_vendor.git
```

2. **Build Fast-CDR (required dependency)**:
```bash
cd Fast-CDR
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
cd ../..
```

3. **Build foonathan_memory (required dependency)**:
```bash
cd foonathan_memory_vendor
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
cd ../..
```

4. **Build Fast-DDS**:
```bash
cd ..
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig
```

### Verify Installation

```bash
# Check if libraries are properly installed
ldconfig -p | grep fastdds
ldconfig -p | grep fastcdr
```

## Basic Concepts

### DDS Core Concepts

1. **Domain Participant**: DDS domain participant, manages other DDS entities
2. **Publisher**: Manages one or more DataWriters
3. **Subscriber**: Manages one or more DataReaders
4. **DataWriter**: Publishes data of a specific type
5. **DataReader**: Receives data of a specific type
6. **Topic**: Defines data type and name

### Data Flow Pattern

```
Publisher Application               Subscriber Application
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

## Quick Start - Hello World Example

The Hello World example demonstrates basic Fast-DDS usage with a publisher and subscriber.

### Example Structure

```
examples/cpp/hello_world/
├── Application.cpp          # Application base class
├── Application.hpp
├── CLIParser.hpp           # Command line parsing
├── HelloWorld.idl          # IDL data type definition
├── HelloWorld.hpp          # Generated data type
├── HelloWorldPubSubTypes.* # Generated serialization types
├── ListenerSubscriberApp.* # Listener-based subscriber
├── PublisherApp.*          # Publisher application
├── WaitsetSubscriberApp.*  # Waitset-based subscriber
├── main.cpp               # Main program entry
├── hello_world_profile.xml # XML configuration file
└── README.md              # Detailed documentation
```

### Data Type Definition

The example uses a simple `HelloWorld` message type:

```cpp
// HelloWorld.idl content
struct HelloWorld
{
    unsigned long index;
    string message;
};
```

### Publisher Code Analysis

The publisher creates the following DDS entities:
1. Domain Participant
2. Publisher  
3. Topic
4. DataWriter

Main functionality:
- Periodically sends HelloWorld messages
- Each message contains an incrementing index and "Hello world" text
- Waits for subscriber connection before starting to send

### Subscriber Code Analysis

The subscriber supports two receiving modes:

1. **Listener Mode (default)**:
   - Uses callback functions to handle new data
   - Automatically triggered when new data arrives

2. **Waitset Mode**:
   - Uses a dedicated thread to wait for status changes
   - Enable with `--waitset` parameter

## Running Examples

### Building Hello World Example

```bash
cd examples/cpp/hello_world
mkdir build && cd build
cmake ..
make
```

### Running Publisher

In the first terminal:
```bash
./hello_world publisher
```

Expected output:
```
Publisher running. Please press Ctrl+C to stop the Publisher at any time.
Publisher matched.
Message: 'Hello world' with index: '1' SENT
Message: 'Hello world' with index: '2' SENT
Message: 'Hello world' with index: '3' SENT
...
```

### Running Subscriber

In the second terminal:
```bash
./hello_world subscriber
```

Expected output:
```
Subscriber running. Please press Ctrl+C to stop the Subscriber at any time.
Subscriber matched.
Message: 'Hello world' with index: '1' RECEIVED
Message: 'Hello world' with index: '2' RECEIVED
Message: 'Hello world' with index: '3' RECEIVED
...
```

### Using Waitset Mode

```bash
./hello_world subscriber --waitset
```

### Command Line Options

View all available options:
```bash
./hello_world --help
```

Common options:
- `--samples <count>`: Stop after sending/receiving specified number of samples
- `--domain <ID>`: Specify DDS domain ID
- `--interval <ms>`: Set publishing interval

## Advanced Usage

### XML Configuration Files

Fast-DDS supports QoS policy configuration through XML files:

```bash
export FASTDDS_DEFAULT_PROFILES_FILE=hello_world_profile.xml
./hello_world publisher
```

Example XML configuration includes:
- **Reliability settings**: Avoid sample loss
- **Durability settings**: Support late-joining subscribers to receive previous samples
- **History settings**: Keep a certain number of historical samples

### QoS (Quality of Service) Policies

Fast-DDS supports various QoS policies:

1. **Reliability**:
   - `RELIABLE`: Guarantees data delivery
   - `BEST_EFFORT`: Best effort delivery, no guarantee

2. **Durability**:
   - `VOLATILE`: Data is not persisted
   - `TRANSIENT_LOCAL`: Local persistence

3. **History**:
   - `KEEP_LAST`: Keep the latest N samples
   - `KEEP_ALL`: Keep all samples

## More Examples

The repository contains multiple examples showcasing different features:

### 1. Discovery Server
```bash
cd examples/cpp/discovery_server
```
- Demonstrates centralized discovery mechanism
- Reduces network traffic
- Suitable for large-scale deployments

### 2. Content Filter
```bash
cd examples/cpp/content_filter
```
- Content-based message filtering
- SQL-style filter expressions
- Reduces unnecessary data transmission

### 3. Security
```bash
cd examples/cpp/security
```
- TLS/DTLS encryption
- Authentication and authorization
- Data integrity protection

### 4. Custom Payload Pool
```bash
cd examples/cpp/custom_payload_pool
```
- Custom memory management
- Optimizes large data transfers
- Reduces memory copying

### 5. Static EDP Discovery
```bash
cd examples/cpp/static_edp_discovery
```
- Pre-configured endpoint discovery
- No dynamic discovery process needed
- Suitable for deterministic environments

## Official Documentation and Resources

### Official Documentation
- [Fast-DDS Online Documentation](https://fast-dds.docs.eprosima.com)
- [Installation Guide](https://fast-dds.docs.eprosima.com/en/latest/installation/binaries/binaries_linux.html)
- [User Manual](https://fast-dds.docs.eprosima.com/en/latest/fastdds/getting_started/getting_started.html)
- [API Reference](https://fast-dds.docs.eprosima.com/en/latest/fastdds/api_reference/api_reference.html)

### Tools and Utilities
- [Fast-DDS-Gen](https://fast-dds.docs.eprosima.com/en/latest/fastddsgen/introduction/introduction.html): IDL code generator
- [Fast-DDS CLI](https://fast-dds.docs.eprosima.com/en/latest/fastddscli/cli/cli.html): Command line tool
- [Shapes Demo](https://eprosima-shapes-demo.readthedocs.io/): Graphical demo application
- [Fast-DDS Monitor](https://fast-dds-monitor.readthedocs.io/): Monitoring tool

### Community and Support
- [GitHub Repository](https://github.com/eProsima/Fast-DDS)
- [eProsima Website](https://eprosima.com/)
- [ROS 2 Documentation](https://docs.ros.org/en/rolling/Concepts/About-Middleware-Implementations.html)

### Docker Image
eProsima provides pre-built Docker images containing:
- Fast-DDS libraries and examples
- Shapes Demo
- Fast-DDS Monitor
- Complete development environment

```bash
# Download and run Docker image
docker pull eprosima/fast-dds:latest
docker run -it --rm eprosima/fast-dds:latest
```

---

## Troubleshooting

### Common Issues

1. **Build fails - missing dependencies**:
   ```bash
   # Ensure all dependencies are installed
   sudo apt install cmake g++ libasio-dev libtinyxml2-dev libssl-dev
   ```

2. **Runtime library not found**:
   ```bash
   # Update library cache
   sudo ldconfig
   # Check LD_LIBRARY_PATH
   export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
   ```

3. **Firewall issues**:
   ```bash
   # Fast-DDS uses UDP multicast, ensure firewall allows relevant ports
   sudo ufw allow 7400:7500/udp
   ```

4. **Multicast not working**:
   ```bash
   # Enable loopback multicast
   sudo route add -net 224.0.0.0 netmask 240.0.0.0 dev lo
   ```

### Debugging Tips

1. **Enable verbose logging**:
   ```cpp
   eprosima::fastdds::dds::Log::SetVerbosity(eprosima::fastdds::dds::Log::Kind::Info);
   ```

2. **Use XML configuration for debugging**:
   ```xml
   <log>
       <use_default>TRUE</use_default>
       <consumer>
           <class>StdoutConsumer</class>
       </consumer>
   </log>
   ```

3. **Network diagnostics**:
   ```bash
   # Check multicast traffic
   tcpdump -i any multicast
   # Check Fast-DDS ports
   netstat -an | grep 7400
   ```

---

This guide provides you with complete introductory knowledge for using Fast-DDS. We recommend starting with the Hello World example and then gradually exploring more advanced features and examples.

## Using This Repository

### Files Added for Learning:
- `如何使用Fast-DDS指南.md` - Comprehensive Chinese learning guide
- `HOW_TO_USE_FAST_DDS.md` - This English learning guide  
- `quick_start.sh` - Automated setup and build script

### Quick Commands:
```bash
# View Chinese guide
cat 如何使用Fast-DDS指南.md

# View English guide  
cat HOW_TO_USE_FAST_DDS.md

# Quick start with automated setup
./quick_start.sh --install-deps --demo
```
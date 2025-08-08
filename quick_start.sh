#!/bin/bash

# Fast-DDS 快速启动脚本 (Fast-DDS Quick Start Script)
# 此脚本帮助用户快速设置和构建 Fast-DDS

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查系统要求
check_requirements() {
    print_info "检查系统要求..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_success "检测到 Linux 系统"
        DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
        print_info "发行版: $DISTRO"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_success "检测到 macOS 系统"
    else
        print_warning "未测试的操作系统: $OSTYPE"
    fi
    
    # 检查必需工具
    local tools=("cmake" "g++" "git" "make")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_success "所有必需工具都已安装"
    else
        print_error "缺少以下工具: ${missing_tools[*]}"
        print_info "请运行脚本时添加 --install-deps 参数来自动安装依赖项"
        return 1
    fi
}

# 安装依赖项
install_dependencies() {
    print_info "安装依赖项..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            print_info "使用 apt-get 安装依赖项..."
            sudo apt-get update
            sudo apt-get install -y \
                cmake \
                g++ \
                python3-pip \
                wget \
                git \
                libasio-dev \
                libtinyxml2-dev \
                libssl-dev \
                build-essential
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            print_info "使用 yum 安装依赖项..."
            sudo yum install -y \
                cmake \
                gcc-c++ \
                python3-pip \
                wget \
                git \
                asio-devel \
                tinyxml2-devel \
                openssl-devel
        elif command -v dnf &> /dev/null; then
            # Fedora
            print_info "使用 dnf 安装依赖项..."
            sudo dnf install -y \
                cmake \
                gcc-c++ \
                python3-pip \
                wget \
                git \
                asio-devel \
                tinyxml2-devel \
                openssl-devel
        else
            print_error "不支持的包管理器，请手动安装依赖项"
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            print_info "使用 Homebrew 安装依赖项..."
            brew install cmake git openssl asio tinyxml2
        else
            print_error "请先安装 Homebrew: https://brew.sh/"
            return 1
        fi
    fi
    
    print_success "依赖项安装完成"
}

# 构建 Fast-CDR
build_fastcdr() {
    print_info "构建 Fast-CDR (必需依赖)..."
    
    if [ ! -d "Fast-CDR" ]; then
        git clone https://github.com/eProsima/Fast-CDR.git
    fi
    
    cd Fast-CDR
    if [ ! -d "build" ]; then
        mkdir build
    fi
    cd build
    
    cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    if [ "$INSTALL_SYSTEM_WIDE" = true ]; then
        sudo make install
    else
        make install
    fi
    
    cd ../..
    print_success "Fast-CDR 构建完成"
}

# 构建 foonathan_memory
build_foonathan_memory() {
    print_info "构建 foonathan_memory (必需依赖)..."
    
    if [ ! -d "foonathan_memory_vendor" ]; then
        git clone https://github.com/eProsima/foonathan_memory_vendor.git
    fi
    
    cd foonathan_memory_vendor
    if [ ! -d "build" ]; then
        mkdir build
    fi
    cd build
    
    cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    if [ "$INSTALL_SYSTEM_WIDE" = true ]; then
        sudo make install
    else
        make install
    fi
    
    cd ../..
    print_success "foonathan_memory 构建完成"
}

# 构建 Fast-DDS
build_fastdds() {
    print_info "构建 Fast-DDS..."
    
    if [ ! -d "build" ]; then
        mkdir build
    fi
    cd build
    
    cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    if [ "$INSTALL_SYSTEM_WIDE" = true ]; then
        sudo make install
        sudo ldconfig 2>/dev/null || true
    else
        make install
    fi
    
    cd ..
    print_success "Fast-DDS 构建完成"
}

# 构建 Hello World 示例
build_hello_world() {
    print_info "构建 Hello World 示例..."
    
    cd examples/cpp/hello_world
    if [ ! -d "build" ]; then
        mkdir build
    fi
    cd build
    
    if [ "$INSTALL_SYSTEM_WIDE" = false ]; then
        export CMAKE_PREFIX_PATH="$INSTALL_PREFIX:$CMAKE_PREFIX_PATH"
        export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH"
        export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
    fi
    
    cmake ..
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    cd ../../..
    print_success "Hello World 示例构建完成"
}

# 运行演示
run_demo() {
    print_info "准备运行 Hello World 演示..."
    
    DEMO_PATH="examples/cpp/hello_world/build"
    
    if [ ! -f "$DEMO_PATH/hello_world" ]; then
        print_error "Hello World 示例未找到，请先构建"
        return 1
    fi
    
    print_success "Hello World 示例已准备就绪！"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    快速演示指南"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "1. 打开第一个终端，运行发布者："
    echo "   cd $(pwd)/$DEMO_PATH"
    echo "   ./hello_world publisher"
    echo ""
    echo "2. 打开第二个终端，运行订阅者："
    echo "   cd $(pwd)/$DEMO_PATH"
    echo "   ./hello_world subscriber"
    echo ""
    echo "3. 您将看到消息在两个应用程序之间传递"
    echo ""
    echo "4. 使用 Ctrl+C 停止应用程序"
    echo ""
    echo "其他选项："
    echo "   - 使用等待集模式: ./hello_world subscriber --waitset"
    echo "   - 查看帮助: ./hello_world --help"
    echo "   - 发送指定数量的消息: ./hello_world publisher --samples 10"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# 清理构建文件
clean_build() {
    print_info "清理构建文件..."
    
    local dirs=("build" "Fast-CDR/build" "foonathan_memory_vendor/build" "examples/cpp/hello_world/build")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_info "已删除 $dir"
        fi
    done
    
    print_success "清理完成"
}

# 显示帮助信息
show_help() {
    echo "Fast-DDS 快速启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --install-deps     安装系统依赖项"
    echo "  --local-install    安装到本地目录而不是系统目录"
    echo "  --prefix DIR       指定安装前缀 (默认: /usr/local 或 ~/.local)"
    echo "  --build-only       仅构建，不安装"
    echo "  --clean            清理构建文件"
    echo "  --demo             构建完成后运行演示指南"
    echo "  --help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --install-deps --demo    # 安装依赖项并构建，然后显示演示指南"
    echo "  $0 --local-install         # 安装到用户目录"
    echo "  $0 --clean                 # 清理所有构建文件"
}

# 主函数
main() {
    # 默认参数
    INSTALL_DEPS=false
    INSTALL_SYSTEM_WIDE=true
    INSTALL_PREFIX="/usr/local"
    BUILD_ONLY=false
    CLEAN=false
    SHOW_DEMO=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-deps)
                INSTALL_DEPS=true
                shift
                ;;
            --local-install)
                INSTALL_SYSTEM_WIDE=false
                INSTALL_PREFIX="$HOME/.local"
                shift
                ;;
            --prefix)
                INSTALL_PREFIX="$2"
                shift 2
                ;;
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --demo)
                SHOW_DEMO=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_info "Fast-DDS 快速启动脚本"
    echo "安装位置: $INSTALL_PREFIX"
    echo "系统安装: $INSTALL_SYSTEM_WIDE"
    echo ""
    
    # 清理模式
    if [ "$CLEAN" = true ]; then
        clean_build
        exit 0
    fi
    
    # 检查是否在 Fast-DDS 目录中
    if [ ! -f "CMakeLists.txt" ] || [ ! -d "examples" ]; then
        print_error "请在 Fast-DDS 根目录中运行此脚本"
        exit 1
    fi
    
    # 创建依赖项目录
    if [ ! -d "deps" ]; then
        mkdir deps
    fi
    cd deps
    
    # 安装依赖项
    if [ "$INSTALL_DEPS" = true ]; then
        install_dependencies
    fi
    
    # 检查系统要求
    if ! check_requirements; then
        exit 1
    fi
    
    # 构建依赖项
    build_fastcdr
    build_foonathan_memory
    
    cd ..
    
    # 构建 Fast-DDS
    build_fastdds
    
    # 构建示例
    build_hello_world
    
    # 显示演示指南
    if [ "$SHOW_DEMO" = true ]; then
        run_demo
    fi
    
    print_success "Fast-DDS 构建完成！"
    
    if [ "$INSTALL_SYSTEM_WIDE" = false ]; then
        echo ""
        print_warning "使用本地安装，请设置以下环境变量："
        echo "export CMAKE_PREFIX_PATH=\"$INSTALL_PREFIX:\$CMAKE_PREFIX_PATH\""
        echo "export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""
        echo "export PKG_CONFIG_PATH=\"$INSTALL_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""
    fi
    
    echo ""
    print_info "查看完整使用指南: cat 如何使用Fast-DDS指南.md"
}

# 运行主函数
main "$@"
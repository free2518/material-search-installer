#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 错误处理函数
handle_error() {
    echo -e "${RED}错误: $1${NC}"
    exit 1
}

echo -e "${GREEN}开始安装 MaterialSearch...${NC}"

# 检查是否已安装 Homebrew
if ! command -v brew &> /dev/null; then
    echo "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || handle_error "Homebrew 安装失败"
else
    echo "✓ Homebrew 已安装"
fi

# 安装 Python 和 ffmpeg
echo "正在安装必要的依赖..."
brew install python ffmpeg || handle_error "依赖安装失败"

# 检查 git 是否安装
if ! command -v git &> /dev/null; then
    echo "正在安装 git..."
    brew install git || handle_error "Git 安装失败"
fi

# 创建项目目录
echo "正在创建项目目录..."
mkdir -p ~/MaterialSearch || handle_error "无法创建项目目录"
cd ~/MaterialSearch || handle_error "无法进入项目目录"

# 克隆项目
echo "正在克隆项目..."
if [ -d ".git" ]; then
    git pull || handle_error "项目更新失败"
else
    git clone https://github.com/IuvenisSapiens/MaterialSearch.git . || handle_error "项目克隆失败"
fi

# 创建虚拟环境
echo "正在创建虚拟环境..."
python3 -m venv venv || handle_error "虚拟环境创建失败"
source venv/bin/activate || handle_error "虚拟环境激活失败"

# 安装 Rust 和 Cargo
echo "正在安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || handle_error "Rust 安装失败"
source "$HOME/.cargo/env"

# 在安装依赖之前添加这些行
echo "正在配置 Hugging Face..."
export TRANSFORMERS_OFFLINE=0
export HF_ENDPOINT=https://huggingface.co
export HF_HUB_ENABLE_HF_TRANSFER=1

# 安装依赖
echo "正在安装 Python 依赖..."
pip install --upgrade pip || handle_error "pip 更新失败"
pip install huggingface_hub hf_transfer || handle_error "Hugging Face Hub 安装失败"

# 先安装 PyTorch
echo "正在安装 PyTorch..."
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cpu || handle_error "PyTorch 安装失败"

# 然后安装其他依赖
pip install -U -r requirements.txt || handle_error "Python 依赖安装失败"

# 创建模型配置文件
echo "正在创建模型配置文件..."
cat > models.sh << EOL
#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
NC='\033[0m'

# 选择模型
select_model() {
    echo "请选择要使用的模型："
    echo "1) chinese-clip-vit-base-patch16 (默认，平衡型，753MB)"
    echo "2) chinese-clip-vit-large-patch14 (高性能，3GB)"
    echo "3) chinese-clip-rn50 (快速，体积小)"
    read -p "请输入选择 (1-3): " choice

    case \$choice in
        1) model="OFA-Sys/chinese-clip-vit-base-patch16";;
        2) model="OFA-Sys/chinese-clip-vit-large-patch14";;
        3) model="OFA-Sys/chinese-clip-rn50";;
        *) model="OFA-Sys/chinese-clip-vit-base-patch16";;
    esac

    # 更新配置文件
    echo "ASSETS_PATH=\$HOME/Pictures,\$HOME/Movies" > .env
    echo "DEVICE=cpu" >> .env
    echo "MODEL_NAME=\$model" >> .env
    echo -e "\${GREEN}已切换到模型: \$model\${NC}"
}

select_model
EOL

chmod +x models.sh

# 创建配置文件
echo "正在创建配置文件..."
cat > .env << EOL
ASSETS_PATH=$HOME/Pictures,$HOME/Movies
DEVICE=cpu
MODEL_NAME=OFA-Sys/chinese-clip-vit-base-patch16
EOL

# 修改启动脚本
cat > start.sh << EOL
#!/bin/bash
cd \$(dirname \$0)
source venv/bin/activate

# 设置 Hugging Face 环境变量
export TRANSFORMERS_OFFLINE=0
export HF_ENDPOINT=https://huggingface.co
export HF_HUB_ENABLE_HF_TRANSFER=1

# 设置 Rust 环境
source "\$HOME/.cargo/env"

# 询问是否切换模型
read -p "是否切换模型? (y/n): " switch_model
if [ "\$switch_model" = "y" ]; then
    ./models.sh
fi

python main.py
EOL

# 设置启动脚本权限
chmod +x start.sh || handle_error "无法设置启动脚本权限"

# 创建桌面快捷方式
echo "正在创建桌面快捷方式..."
DESKTOP_PATH="$HOME/Desktop"
if [ -d "$DESKTOP_PATH" ]; then
    cat > "$DESKTOP_PATH/MaterialSearch.command" << EOL
#!/bin/bash
cd ~/MaterialSearch
./start.sh
EOL
    if ! chmod +x "$DESKTOP_PATH/MaterialSearch.command"; then
        echo -e "${RED}警告: 无法设置桌面快捷方式权限${NC}"
        echo "你可以手动运行以下命令设置权限："
        echo "chmod +x ~/Desktop/MaterialSearch.command"
    else
        echo -e "${GREEN}✓ 桌面快捷方式创建成功${NC}"
    fi
else
    echo -e "${RED}警告: 未找到桌面目录，跳过创建快捷方式${NC}"
fi

echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}你可以通过以下方式启动程序：${NC}"
echo "1. 双击桌面上的 MaterialSearch.command (如果创建成功)"
echo "2. 或者在终端中运行:"
echo "   cd ~/MaterialSearch"
echo "   ./start.sh"
echo -e "${GREEN}启动后访问 http://localhost:8085 即可使用${NC}"

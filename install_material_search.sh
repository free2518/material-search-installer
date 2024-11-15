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

# 替换 config.py 和 scan.py
echo "正在更新配置文件..."
cat > config.py << 'EOL'
import os

from dotenv import load_dotenv

# 加载.env文件中的环境变量
load_dotenv()

# *****服务器配置*****
HOST = os.getenv('HOST', '0.0.0.0')  # 监听IP，如果只想本地访问，把这个改成127.0.0.1
PORT = int(os.getenv('PORT', 8085))  # 监听端口

# *****扫描配置*****
ASSETS_PATH = tuple(os.getenv('ASSETS_PATH', '~/Pictures,~/Movies').split(','))  # 素材所在的目录，绝对路径，逗号分隔
SKIP_PATH = tuple(os.getenv('SKIP_PATH', '/tmp').split(','))  # 跳过扫描的目录，绝对路径，逗号分隔
IMAGE_EXTENSIONS = tuple(os.getenv('IMAGE_EXTENSIONS', '.jpg,.jpeg,.png,.gif,.heic,.webp,.bmp').split(','))  # 支持的图片拓展名，逗号分隔，请填小写
VIDEO_EXTENSIONS = tuple(os.getenv('VIDEO_EXTENSIONS', '.mp4,.flv,.mov,.mkv,.webm,.avi').split(','))  # 支持的视频拓展名，逗号分隔，请填小写
IGNORE_STRINGS = tuple(os.getenv('IGNORE_STRINGS', 'thumb,avatar,__MACOSX,icons,cache').lower().split(','))  # 如果路径或文件名包含这些字符串，就跳过，逗号分隔，不区分大小写
FRAME_INTERVAL = int(os.getenv('FRAME_INTERVAL', 2))  # 视频每隔多少秒取一帧，视频展示的时候，间隔小于等于2倍FRAME_INTERVAL的算为同一个素材，同时开始时间和结束时间各延长0.5个FRAME_INTERVAL
SCAN_PROCESS_BATCH_SIZE = int(os.getenv('SCAN_PROCESS_BATCH_SIZE', 8))  # 等读取的帧数到这个数量后再一次性输入到模型中进行批量计算，从而提高效率。显存较大可以调高这个值。
IMAGE_MIN_WIDTH = int(os.getenv('IMAGE_MIN_WIDTH', 64))  # 图片最小宽度，小于此宽度则忽略。不需要可以改成0。
IMAGE_MIN_HEIGHT = int(os.getenv('IMAGE_MIN_HEIGHT', 64))  # 图片最小高度，小于此高度则忽略。不需要可以改成0。
AUTO_SCAN = os.getenv('AUTO_SCAN', 'False').lower() == 'true'  # 是否自动扫描，如果开启，则会在指定时间内进行扫描
AUTO_SCAN_START_TIME = tuple(map(int, os.getenv('AUTO_SCAN_START_TIME', '22:30').split(':')))  # 自动扫描开始时间
AUTO_SCAN_END_TIME = tuple(map(int, os.getenv('AUTO_SCAN_END_TIME', '8:00').split(':')))  # 自动扫描结束时间
AUTO_SAVE_INTERVAL = int(os.getenv('AUTO_SAVE_INTERVAL', 100))  # 扫描自动保存间隔，默认为每 100 个文件自动保存一次
SCAN_PATHS = tuple(os.getenv('SCAN_PATHS', '').split(',') if os.getenv('SCAN_PATHS') else [])  # 增量扫描的目录
INCREMENTAL_SCAN = os.getenv('INCREMENTAL_SCAN', 'False').lower() == 'true'  # 是否为增量扫描

# *****模型配置*****
MODEL_NAME = os.getenv('MODEL_NAME', "OFA-Sys/chinese-clip-vit-base-patch16")  # CLIP模型
DEVICE = os.getenv('DEVICE', 'cpu')  # 推理设备，cpu/cuda/mps，建议先跑benchmark.py看看cpu还是显卡速度更快。因为数据搬运也需要时间，所以不一定是GPU更快。

# *****搜索配置*****
CACHE_SIZE = int(os.getenv('CACHE_SIZE', 64))  # 搜索缓存条目数量，表示缓存最近的n次搜索结果，0表示不缓存。缓存保存在内存中。图片搜索和视频搜索分开缓存。
POSITIVE_THRESHOLD = int(os.getenv('POSITIVE_THRESHOLD', 36))  # 正向搜索词搜出来的素材，高于这个分数才展示。这个是默认值，用的时候可以在前端修改。
NEGATIVE_THRESHOLD = int(os.getenv('NEGATIVE_THRESHOLD', 36))  # 反向搜索词搜出来的素材，低于这个分数才展示。这个是默认值，用的时候可以在前端修改。
IMAGE_THRESHOLD = int(os.getenv('IMAGE_THRESHOLD', 85))  # 图片搜出来的素材，高于这个分数才展示。这个是默认值，用的时候可以在前端修改。

# *****日志配置*****
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')  # 日志等级：NOTSET/DEBUG/INFO/WARNING/ERROR/CRITICAL

# *****其它配置*****
DATA_DIR = os.path.expanduser('~/MaterialSearch/data')
DATABASE_PATH = os.path.expanduser('~/MaterialSearch/instance/assets.db')
SQLALCHEMY_DATABASE_URL = f'sqlite:///{DATABASE_PATH}'  # 数据库保存路径
TEMP_PATH = os.getenv('TEMP_PATH', './tmp')  # 临时目录路径
VIDEO_EXTENSION_LENGTH = int(os.getenv('VIDEO_EXTENSION_LENGTH', 0))  # 下载视频片段时，视频前后增加的时长，单位为秒
ENABLE_LOGIN = os.getenv('ENABLE_LOGIN', 'False').lower() == 'true'  # 是否启用登录
USERNAME = os.getenv('USERNAME', 'admin')  # 登录用户名
PASSWORD = os.getenv('PASSWORD', 'MaterialSearch')  # 登录密码
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'  # flask 调试开关（热重载）

# *****打印配置内容*****
print("********** 运行配置 / RUNNING CONFIGURATIONS **********")
global_vars = globals().copy()
for var_name, var_value in global_vars.items():
    if var_name[0].isupper():
        print(f"{var_name}: {var_value!r}")
print(f"HF_HOME: {os.getenv('HF_HOME')}")
print(f"HF_HUB_OFFLINE: {os.getenv('HF_HUB_OFFLINE')}")
print(f"TRANSFORMERS_OFFLINE: {os.getenv('TRANSFORMERS_OFFLINE')}")
print(f"CWD: {os.getcwd()}")
print("**************************************************")
EOL

cat > scan.py << 'EOL'
import datetime
import logging
import pickle
import time
from pathlib import Path

from config import *
from database import (
    get_image_count,
    get_video_count,
    get_video_frame_count,
    delete_record_if_not_exist,
    delete_image_if_outdated,
    delete_video_if_outdated,
    add_video,
    add_image,
)
from models import create_tables, DatabaseSession
from process_assets import process_images, process_video
from search import clean_cache


class Scanner:
    """
    扫描类
    """

    def __init__(self) -> None:
        # 全局变量
        self.scanned = False  # 表示本次自动扫描时间段内是否以及扫描过
        self.is_scanning = False
        self.scan_start_time = 0
        self.scanning_files = 0
        self.total_images = 0
        self.total_videos = 0
        self.total_video_frames = 0
        self.scanned_files = 0
        self.is_continue_scan = False
        self.logger = logging.getLogger(__name__)
        self.temp_file = f"{TEMP_PATH}/assets.pickle"
        self.assets = set()

        # 自动扫描时间
        self.start_time = datetime.time(*AUTO_SCAN_START_TIME)
        self.end_time = datetime.time(*AUTO_SCAN_END_TIME)
        self.is_cross_day = self.start_time > self.end_time  # 是否跨日期

        # 处理跳过路径
        self.skip_paths = [Path(i) for i in SKIP_PATH if i]
        self.ignore_keywords = [i for i in IGNORE_STRINGS if i]
        self.extensions = IMAGE_EXTENSIONS + VIDEO_EXTENSIONS

    def init(self):
        create_tables()
        with DatabaseSession() as session:
            self.total_images = get_image_count(session)
            self.total_videos = get_video_count(session)
            self.total_video_frames = get_video_frame_count(session)

    def get_status(self):
        """
        获取扫描状态信息
        :return: dict, 状态信息字典
        """
        if self.scanned_files:
            remain_time = (
                    (time.time() - self.scan_start_time)
                    / self.scanned_files
                    * self.scanning_files
            )
        else:
            remain_time = 0
        if self.is_scanning and self.scanning_files != 0:
            progress = self.scanned_files / self.scanning_files
        else:
            progress = 0
        return {
            "status": self.is_scanning,
            "total_images": self.total_images,
            "total_videos": self.total_videos,
            "total_video_frames": self.total_video_frames,
            "scanning_files": self.scanning_files,
            "remain_files": self.scanning_files - self.scanned_files,
            "progress": progress,
            "remain_time": int(remain_time),
            "enable_login": ENABLE_LOGIN,
        }

    def save_assets(self):
        with open(self.temp_file, "wb") as f:
            pickle.dump(self.assets, f)

    def filter_path(self, path) -> bool:
        """
        过滤跳过的路径
        """
        if type(path) == str:
            path = Path(path)
        wrong_ext = path.suffix.lower() not in self.extensions
        skip = any((path.is_relative_to(p) for p in self.skip_paths))
        ignore = any((keyword in str(path).lower() for keyword in self.ignore_keywords))
        self.logger.debug(f"{path} 不匹配后缀：{wrong_ext} 跳过：{skip} 忽略：{ignore}")
        return not any((wrong_ext, skip, ignore))

    def generate_or_load_assets(self):
        """
        若无缓存文件，扫描目录到self.assets, 并生成新的缓存文件；
        否则加载缓存文件到self.assets
        :return: None
        """
        if os.path.isfile(self.temp_file):
            self.logger.info("读取上次的目录缓存")
            self.is_continue_scan = True
            with open(self.temp_file, "rb") as f:
                self.assets = pickle.load(f)
            self.assets = set((i for i in filter(self.filter_path, self.assets)))
        else:
            self.is_continue_scan = False
            self.scan_dir()
            self.save_assets()
        self.scanning_files = len(self.assets)

    def is_current_auto_scan_time(self) -> bool:
        """
        判断当前时间是否在自动扫描时间段内
        :return: 当前时间是否在自动扫描时间段内时返回True，否则返回False
        """
        current_time = datetime.datetime.now().time()
        is_in_range = (
                self.start_time <= current_time < self.end_time
        )  # 当前时间是否在 start_time 与 end_time 区间内
        return self.is_cross_day ^ is_in_range  # 跨日期与在区间内异或时，在自动扫描时间内

    def auto_scan(self):
        """
        自动扫描，每5秒判断一次时间，如果在目标时间段内则开始扫描。
        :return: None
        """
        while True:
            time.sleep(5)
            if self.is_scanning:
                self.scanned = True  # 设置扫描标记，这样如果手动扫描在自动扫描时间段内结束，也不会重新扫描
            elif not self.is_current_auto_scan_time():
                self.scanned = False  # 已经过了自动扫描时间段，重置扫描标记
            elif not self.scanned and self.is_current_auto_scan_time():
                self.logger.info("触发自动扫描")
                self.scanned = True  # 表示本目标时间段内已进行扫描，防止同个时间段内扫描多次
                self.scan(True)

    def scan_dir(self):
        """
        遍历文件并将符合条件的文件加入 assets 集合
        """
        self.assets = set()
        
        # 如果是增量扫描，只扫描指定目录
        if INCREMENTAL_SCAN and SCAN_PATHS:
            paths = [Path(i) for i in SCAN_PATHS if i]
        else:
            paths = [Path(i) for i in ASSETS_PATH if i]
            
        # 遍历根目录及其子目录下的所有文件
        for path in paths:
            for file in filter(self.filter_path, path.rglob("*")):
                self.assets.add(str(file))

    def handle_image_batch(self, session, image_batch_dict):
        path_list, features_list = process_images(list(image_batch_dict.keys()))
        if not path_list or features_list is None:
            return
        for path, features in zip(path_list, features_list):
            # 写入数据库
            features = features.tobytes()
            modify_time = image_batch_dict[path]
            add_image(session, path, modify_time, features)
            self.assets.remove(path)
        self.total_images = get_image_count(session)

    def scan(self, auto=False):
        """
        扫描资源。如果存在assets.pickle，则直接读取并开始扫描。如果不存在，则先读取所有文件路径，并写入assets.pickle，然后开始扫描。
        每100个文件重新保存一次assets.pickle，如果程序被中断，下次可以从断点处继续扫描。扫描完成后删除assets.pickle并清缓存。
        :param auto: 是否由AUTO_SCAN触发的
        """
        self.logger.info("开始扫描")
        self.is_scanning = True
        self.scan_start_time = time.time()
        self.generate_or_load_assets()
        
        with DatabaseSession() as session:
            # 只在非增量扫描时删除不存在的记录
            if not INCREMENTAL_SCAN and not self.is_continue_scan:
                delete_record_if_not_exist(session, self.assets)
                
            # 扫描文件
            image_batch_dict = {}  # 批量处理文件的字典，用字典方便某个图片有问题的时候的处理
            for path in self.assets.copy():
                self.scanned_files += 1
                if self.scanned_files % AUTO_SAVE_INTERVAL == 0:  # 每扫描 AUTO_SAVE_INTERVAL 个文件重新save一下
                    self.save_assets()
                if auto and not self.is_current_auto_scan_time():  # 如果是自动扫描，判断时间自动停止
                    self.logger.info(f"超出自动扫描时间，停止扫描")
                    break
                # 如果文件不存在，则忽略（扫描时文件被移动或删除则会触发这种情况）
                if not os.path.isfile(path):
                    continue
                modify_time = os.path.getmtime(path)
                modify_time = datetime.datetime.fromtimestamp(modify_time)
                # 如果数据库里有这个文件，并且修改时间一致，则跳过，否则进行预处理并入库
                if path.lower().endswith(IMAGE_EXTENSIONS):  # 图片
                    not_modified = delete_image_if_outdated(session, path)
                    if not_modified:
                        self.assets.remove(path)
                        continue
                    image_batch_dict[path] = modify_time
                    # 达到SCAN_PROCESS_BATCH_SIZE再进行批量处理
                    if len(image_batch_dict) == SCAN_PROCESS_BATCH_SIZE:
                        self.handle_image_batch(session, image_batch_dict)
                        image_batch_dict = {}
                    continue
                elif path.lower().endswith(VIDEO_EXTENSIONS):  # 视频
                    not_modified = delete_video_if_outdated(session, path)
                    if not_modified:
                        self.assets.remove(path)
                        continue
                    add_video(session, path, modify_time, process_video(path))
                    self.total_video_frames = get_video_frame_count(session)
                    self.total_videos = get_video_count(session)
                self.assets.remove(path)
            if len(image_batch_dict) != 0:  # 最后如果图片数量没达到SCAN_PROCESS_BATCH_SIZE，也进行一次处理
                self.handle_image_batch(session, image_batch_dict)
            # 最后重新统计一下数量
            self.total_images = get_image_count(session)
            self.total_videos = get_video_count(session)
            self.total_video_frames = get_video_frame_count(session)
        self.scanning_files = 0
        self.scanned_files = 0
        os.remove(self.temp_file)
        self.logger.info("扫描完成，用时%d秒" % int(time.time() - self.scan_start_time))
        clean_cache()  # 清空搜索缓存
        self.is_scanning = False


if __name__ == '__main__':
    scanner = Scanner()
    scanner.init()
    scanner.scan(False)
EOL

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

    # 读取当前的配置
    if [ -f .env ]; then
        current_path=\$(grep ASSETS_PATH .env | cut -d= -f2-)
        current_device=\$(grep DEVICE .env | cut -d= -f2-)
    else
        current_path="\$HOME/Pictures,\$HOME/Movies"
        current_device="cpu"
    fi

    # 更新配置文件，保留原有设置
    echo "ASSETS_PATH=\$current_path" > .env
    echo "DEVICE=\$current_device" >> .env
    echo "MODEL_NAME=\$model" >> .env
    echo -e "\${GREEN}已切换到模型: \$model${NC}"
    echo -e "\${GREEN}当前扫描路径: \$current_path${NC}"
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

# 询问是否删除数据库
read -p "是否删除数据库并重新扫描? (y/n): " delete_db
if [ "\$delete_db" = "y" ]; then
    rm -f instance/assets.db
else
    # 询问是否要增加扫描目录
    read -p "是否要增加扫描目录? (y/n): " add_path
    if [ "\$add_path" = "y" ]; then
        read -p "请输入要扫描的目录（多个目录用逗号分隔）: " new_paths
        export SCAN_PATHS="\$new_paths"
        export INCREMENTAL_SCAN=true
    fi
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

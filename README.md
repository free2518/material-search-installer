# MaterialSearch MacOS 一键安装脚本

这是一个用于在 MacOS（特别是 M1/M2/M3 芯片）上一键安装 [MaterialSearch](https://github.com/IuvenisSapiens/MaterialSearch) 的脚本。

## 使用方法

清理旧的安装:
rm -rf ~/MaterialSearch

打开终端，复制并运行以下命令：

```
curl -fsSL https://raw.githubusercontent.com/free2518/material-search-installer/main/install_material_search.sh | bash
```

## 功能特点

- 自动安装所需依赖（Homebrew、Python、ffmpeg）
- 自动配置 Python 虚拟环境
- 自动设置启动脚本
- 完整的错误处理
- 友好的安装进度显示
- 支持多种模型切换（base/large/fast）

## 安装后使用

安装完成后，你可以：

1. 进入安装目录：
```
cd ~/MaterialSearch
```

2. 启动程序：
```
./start.sh
```
启动时可以选择是否切换模型：
- chinese-clip-vit-base-patch16 (默认，平衡型，753MB)
- chinese-clip-vit-large-patch14 (高性能，3GB)
- chinese-clip-rn50 (快速，体积小)

3. 打开浏览器访问：`http://localhost:8085`

## 配置说明

安装完成后，配置文件位于 `~/MaterialSearch/.env`。默认配置如下：

```
ASSETS_PATH=$HOME/Pictures,$HOME/Movies
DEVICE=cpu
MODEL_NAME=OFA-Sys/chinese-clip-vit-base-patch16
```

你可以根据需要修改要扫描的文件夹路径。

## 问题反馈

如果在安装过程中遇到任何问题，请在 [Issues](https://github.com/free2518/material-search-installer/issues) 页面提交问题。

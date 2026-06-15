# AI API 开发环境（GitHub Codespaces）

一套预配置的云端开发环境，用于在 **GitHub Codespaces（免费 CPU）** 里写代码并**调用云端大模型 API**（DeepSeek / 通义 / Claude 等）。

打开 Codespace 时会自动：
- 创建 Python 3.11 容器
- 安装 `requirements.txt` 里的依赖（openai、anthropic 等）
- 安装 Python / Jupyter 等 VSCode 扩展

## 一、创建 Codespace

1. 打开本仓库的 GitHub 页面
2. 点绿色 **`Code`** 按钮 → **`Codespaces`** 标签 → **`Create codespace on main`**
3. 等待容器构建（首次约 1-2 分钟），完成后进入网页版 VSCode

> 免费额度：每月 60 核时（2 核机器约 120 小时）+ 15GB 存储。**不用时记得 Stop**，避免空跑消耗额度。

## 二、设置 API Key（二选一）

### 方式 A：Codespaces Secrets（推荐，最安全）

1. GitHub → 头像 → **Settings** → **Codespaces** → **Secrets** → **New secret**
2. 新建 `DEEPSEEK_API_KEY`，值填你的 key，仓库范围选本仓库
3. 重启 Codespace 后，代码里 `os.getenv("DEEPSEEK_API_KEY")` 即可读到

### 方式 B：本地 .env 文件

在 Codespace 终端里：

```bash
cp .env.example .env
# 然后编辑 .env 填入真实 key（.env 不会被提交）
```

## 三、运行示例

```bash
python examples/chat_deepseek.py     # 调用 DeepSeek（含普通 + 流式输出）
python examples/chat_anthropic.py    # 调用 Claude
```

## 四、本地 VSCode 连接 Codespace（可选）

1. 本地 VSCode 安装扩展 **GitHub Codespaces**
2. `F1` → `Codespaces: Connect to Codespace...` → 选择本仓库的 Codespace
3. 即可像 Remote-SSH 一样在本地 VSCode 里操作云端环境

## 目录结构

```
.devcontainer/devcontainer.json   # 开发容器配置
requirements.txt                  # Python 依赖
.env.example                      # API Key 模板（复制为 .env 使用）
examples/chat_deepseek.py         # DeepSeek 调用示例
examples/chat_anthropic.py        # Claude 调用示例
```

## 五、在 Codespace 里使用 Claude Code（第三方 API）

本仓库的 `.devcontainer` 已自动完成：安装 Node.js + Claude Code，并配好 `ANTHROPIC_BASE_URL`（第三方中转地址）。你**只需把令牌存为 Codespaces Secret**（令牌不会进仓库）：

1. GitHub → 头像 → **Settings** → **Codespaces** → **Secrets** → **New secret**
2. 名字填 `ANTHROPIC_AUTH_TOKEN`，值填你的第三方令牌，仓库范围勾选 `ai-codespace`
3. **重新创建 Codespace**（让 devcontainer 配置和 Secret 一起生效）
4. 等容器构建好，终端里运行：

```bash
claude
```

令牌通过 Secret 注入为环境变量，配合 devcontainer 里的 `ANTHROPIC_BASE_URL`，Claude Code 启动即走第三方 API。

> 若想在**已存在**的 Codespace 里临时用（不重建），在终端手动配置：
> ```bash
> npm install -g @anthropic-ai/claude-code
> export ANTHROPIC_BASE_URL="https://api-cc.freemodel.dev"
> export ANTHROPIC_AUTH_TOKEN="你的令牌"
> claude
> ```

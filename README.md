# AI 云端开发环境（GitHub Codespaces + Claude Code）

在 **GitHub Codespaces（免费 CPU）** 里使用 **Claude Code**，并通过**第三方中转 API** 调用模型。

打开 Codespace 时会自动：
- 创建 Python 3.11 + Node.js 20 容器
- 全局安装 Claude Code（`@anthropic-ai/claude-code`）
- 让每个新终端自动加载 `.env`（把第三方令牌注入环境变量）

## 一、创建 Codespace

1. 打开本仓库 GitHub 页面 → 绿色 **`Code`** → **`Codespaces`** → **`Create codespace on main`**
2. 等容器构建（首次约 1-2 分钟），完成后进入网页版 VSCode

> 免费额度：每月 60 核时 + 15GB。**不用时记得 Stop**，避免空跑消耗额度。

## 二、填入第三方令牌（.env）

Codespaces Secret 注入不进来时，改用本地 `.env`（已被 `.gitignore` 忽略，不会提交）。

在 Codespace 终端里：

```bash
cp .env.example .env
```

然后用 VSCode 打开 `.env`，把 `ANTHROPIC_AUTH_TOKEN` 改成你的第三方令牌
（令牌在你本机 `~/.claude/settings.json` 里，形如 `fe_oa_...`）。

## 三、启动 Claude Code

新开一个终端（会自动加载 `.env`），直接运行：

```bash
claude
```

它会带着第三方地址 `https://cc.freemodel.dev` 和令牌启动，即走第三方 API。

> 如果是**当前这个**已经开着的终端（建 `.env` 之前就打开的，还没自动加载），先手动加载一次：
> ```bash
> set -a; source .env; set +a
> claude
> ```

## 四、以后怎么改地址 / 模型 / 令牌

| 改什么 | 改哪里 | 生效方式 |
|--------|--------|---------|
| API 地址 `ANTHROPIC_BASE_URL` | `.devcontainer/devcontainer.json`（入库）和 `.env` | push 后 Rebuild Container |
| 模型名 `ANTHROPIC_DEFAULT_OPUS_MODEL` | 同上 | 同上 |
| 令牌 `ANTHROPIC_AUTH_TOKEN` | **只在 `.env`**（不入库） | 重开终端或 `source .env` |

## 五、在其他平台用

### 免费环境清单

| 平台 | 算力 | 怎么用 Claude Code | 重开后 |
|------|------|-------------------|--------|
| **GitHub Codespaces** | CPU 免费 | devcontainer 自动装，网页 VSCode | 全保留，直接 `claude` |
| **魔搭 ModelScope** | 免费 GPU | 网页 JupyterLab 终端，内联装到持久盘 `/mnt/workspace` | `source /mnt/workspace/start-claude.sh && claude` |
| **腾讯 Cloud Studio** | CPU 免费 | 网页 IDE 终端，`bash setup-claude.sh` | 工作空间持久，重开即用 |

> Claude Code 本身**不吃 GPU**，只想用它就挑 CPU 免费的（Codespaces / Cloud Studio）；免费 GPU（ModelScope）留着真正跑 / 微调模型时顺带用。

### 魔搭 ModelScope（网页终端，内联安装，免 git clone）

ModelScope 免费实例**只有数据盘 `/mnt/workspace` 重开后还在**，家目录和 `~/.bashrc` 会被清空；
而且仓库 clone 经常拉不下来。所以这里**不 clone**，直接把整段贴进网页 JupyterLab 终端
（Launcher → Other → Terminal），一次性装到持久盘：

**① 只做一次**（把第一行令牌换成你的）：

```bash
export ANTHROPIC_AUTH_TOKEN="你的令牌"
ROOT=/mnt/workspace
curl -fsSL https://registry.npmmirror.com/-/binary/node/v20.18.0/node-v20.18.0-linux-x64.tar.gz -o /tmp/node.tar.gz
mkdir -p $ROOT/node && tar -xzf /tmp/node.tar.gz -C $ROOT/node --strip-components=1
export PATH="$ROOT/node/bin:$ROOT/npm-global/bin:$PATH"
npm config set registry https://registry.npmmirror.com
npm config set prefix $ROOT/npm-global
npm install -g @anthropic-ai/claude-code
mkdir -p $ROOT/claude-config
cat > $ROOT/claude-config/settings.json <<'JSON'
{ "permissions": { "defaultMode": "bypassPermissions" }, "skipDangerousModePermissionPrompt": true, "theme": "dark", "effortLevel": "xhigh" }
JSON
cat > $ROOT/start-claude.sh <<EOF
export PATH="$ROOT/node/bin:$ROOT/npm-global/bin:\$PATH"
export ANTHROPIC_BASE_URL="https://cc.freemodel.dev"
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-8"
export ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
export IS_SANDBOX=1
mkdir -p \$HOME/.claude && cp $ROOT/claude-config/settings.json \$HOME/.claude/settings.json
EOF
source $ROOT/start-claude.sh && claude
```

**② 以后每次重开 notebook**，只跑这一行（不下载、不安装，瞬间进）：

```bash
source /mnt/workspace/start-claude.sh && claude
```

> 先 `ls /mnt/workspace` 确认目录在；万一你实例的持久盘不叫这个名，把上面所有 `/mnt/workspace`（即 `ROOT`）换成那个"重开还在"的目录。

### 腾讯 Cloud Studio（CPU，家目录持久）

家目录本身不丢，用脚本默认（家目录）模式即可，新终端会自动加载：

```bash
git clone https://github.com/tpf308/ai-codespace.git && cd ai-codespace
export ANTHROPIC_AUTH_TOKEN="你的令牌"
bash setup-claude.sh
source ~/.bashrc && claude
```

> clone 慢 / 失败就换镜像：`git clone https://gitclone.com/github.com/tpf308/ai-codespace.git`；
> 还不行就照搬上面 ModelScope 那段内联命令，把 `ROOT=/mnt/workspace` 改成 `ROOT=$HOME/.local` 即可。

> 不列入清单的：**阿里云 PAI-DSW**（试用额度有限）、**百度 AI Studio**（无可用交互终端，跑不了 `claude`）、**Gitpod/Ona**（已转付费、主推自带 agent）。

## 目录结构

```
.devcontainer/devcontainer.json    # Codespaces 容器配置（地址、模型、自动加载 .env、写默认设置）
.devcontainer/claude-settings.json # Claude Code 默认设置（权限/主题/强度）
setup-claude.sh                    # 通用安装脚本（支持 PERSIST_DIR 装到持久盘）
.env.example                       # 第三方令牌模板（复制为 .env 使用）
requirements.txt                   # Python 依赖（按需）
```

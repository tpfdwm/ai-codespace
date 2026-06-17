# 多平台云端 Claude Code 环境（第三方中转 API）

在各种**免费云环境**里跑 **Claude Code**，统一通过**第三方中转 API**（`https://cc.freemodel.dev`）调用模型，不用本地装环境。

支持的平台（详见 [第五节](#五在其他平台用)）：

| 平台 | 算力 | 适合 |
|------|------|------|
| **GitHub Codespaces** | CPU 免费 | 最省事，开箱即用（本仓库主用） |
| **魔搭 ModelScope** | 免费 GPU | 顺带跑 / 微调模型 |
| **腾讯 Cloud Studio** | CPU 免费 | 备用 CPU 环境 |

主力是 **GitHub Codespaces**：从本仓库创建 Codespace，会自动
- 建好 Python 3.11 + Node.js 20 容器
- 全局装好 Claude Code（`@anthropic-ai/claude-code`）
- 让每个新终端自动加载 `.env`（把第三方令牌注入环境变量）

> 只想用 Claude Code 就选 CPU 免费的（Codespaces / Cloud Studio）；它本身不吃 GPU。下面一~四节讲 Codespaces，第五节讲其他平台。

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

### 魔搭 ModelScope —— 中转 API 需要科学上网时（anyrouter 等 + mihomo 代理）

有些中转 API（如 `https://anyrouter.top`）从**境内机房直连会被墙**（`curl` 报 `sslv3 alert handshake failure`：TCP 能连、TLS 握手被拦）。
这时在 ModelScope 上本地跑一个 **mihomo** 代理，挂上你自己的机场节点，让 Claude Code 走代理出去即可。

> 前提：你有一份能用的机场**节点配置**（Clash/mihomo 的 `yaml`，含 `proxies`/`proxy-groups`/`rules`），或单条 `hysteria2://`、`vless://` 分享链接。

**① 准备节点配置 → 持久盘**

把你的 Clash 配置文件上传到 `/mnt/workspace`（网页资源管理器拖进去），重命名为 `config.yaml`，然后：

```bash
mkdir -p /mnt/workspace/mihomo-data
mv /mnt/workspace/config.yaml /mnt/workspace/mihomo-data/config.yaml
# 分流默认走"自动选择"（按延迟自动挑能用的节点）
sed -i 's/MATCH,节点选择/MATCH,自动选择/' /mnt/workspace/mihomo-data/config.yaml
# 删掉需要 GeoIP 库的规则（机房连 GitHub 慢，避免卡在下载 MMDB 起不来）
sed -i '/GEOIP/d' /mnt/workspace/mihomo-data/config.yaml
```

**② 下载 mihomo 内核 → 持久盘**

```bash
cd /mnt/workspace
VER=v1.18.10
curl -LO "https://github.com/MetaCubeX/mihomo/releases/download/${VER}/mihomo-linux-amd64-compatible-${VER}.gz"
gunzip -f "mihomo-linux-amd64-compatible-${VER}.gz"
mv -f "mihomo-linux-amd64-compatible-${VER}" mihomo
chmod +x mihomo && ./mihomo -v
```

**③ 代理版启动脚本 `start-claude.sh`**（令牌换成你 anyrouter 的）：

```bash
cat > /mnt/workspace/start-claude.sh <<'EOF'
#!/usr/bin/env bash
# 代理版 —— anyrouter 中转 + 本地 mihomo 代理
export PATH="/mnt/workspace/node/bin:/mnt/workspace/npm-global/bin:$PATH"

# 本地代理 mihomo：没在跑就自动拉起，并等端口就绪
if ! pgrep -f "mihomo -d" >/dev/null 2>&1; then
  echo "正在启动 mihomo 代理..."
  nohup /mnt/workspace/mihomo -d /mnt/workspace/mihomo-data >/mnt/workspace/mihomo-data/mihomo.log 2>&1 &
  for i in $(seq 1 10); do
    ss -tlnp 2>/dev/null | grep -q 127.0.0.1:7890 && break
    sleep 1
  done
fi

# 代理变量（让 Claude Code 走 mihomo）
export HTTPS_PROXY="http://127.0.0.1:7890"
export HTTP_PROXY="http://127.0.0.1:7890"
export NO_PROXY="localhost,127.0.0.1"

# anyrouter 中转 API
export ANTHROPIC_BASE_URL="https://anyrouter.top"
export ANTHROPIC_AUTH_TOKEN="你的anyrouter令牌"
export IS_SANDBOX=1

mkdir -p $HOME/.claude && cp /mnt/workspace/claude-config/settings.json $HOME/.claude/settings.json

# 启动前自检：确认代理能连到 anyrouter
code=$(curl -x http://127.0.0.1:7890 -sS -o /dev/null -w "%{http_code}" --max-time 15 https://anyrouter.top/ 2>/dev/null)
if [ -n "$code" ] && [ "$code" != "000" ]; then
  echo "✅ 代理正常（anyrouter 返回 HTTP $code），可以启动 claude"
else
  echo "⚠️  代理没通，查看日志：tail /mnt/workspace/mihomo-data/mihomo.log"
fi
EOF
```

**④ 直连版启动脚本 `start-direct.sh`**（不走代理，用境内可直连的中转）：

```bash
cat > /mnt/workspace/start-direct.sh <<'EOF'
#!/usr/bin/env bash
# 直连版（不走代理）—— 用境内可直连的中转
export PATH="/mnt/workspace/node/bin:/mnt/workspace/npm-global/bin:$PATH"

# 清掉残留代理变量 + 停掉 mihomo，确保干净直连
unset HTTPS_PROXY HTTP_PROXY ALL_PROXY NO_PROXY https_proxy http_proxy all_proxy no_proxy
pkill -f mihomo 2>/dev/null

# 中转 API（境内可直连）
export ANTHROPIC_BASE_URL="https://cc.freemodel.dev"
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-8"
export ANTHROPIC_AUTH_TOKEN="你的cc.freemodel令牌"
export IS_SANDBOX=1

mkdir -p $HOME/.claude && cp /mnt/workspace/claude-config/settings.json $HOME/.claude/settings.json
EOF
```

> 生成后记得把两个脚本里的 `你的xxx令牌` 换成真实令牌（在编辑器里改，别提交、别截图外发）。

**⑤ 日常使用：选一个脚本 source**

| 场景 | 命令 |
|------|------|
| 走代理（anyrouter） | `source /mnt/workspace/start-claude.sh && claude` |
| 直连（cc.freemodel.dev） | `source /mnt/workspace/start-direct.sh && claude` |

两者互不打架：直连版会清代理 + 停 mihomo；代理版有 `pgrep` 自检会自动把 mihomo 拉起。

> 提示：hysteria2(hy2) 走 UDP，免费机房可能不放行；连不通就在节点里换 `vless`（TCP/443）。机场节点密码、订阅 token 等同账号密码，**别写进入库文件、别截图外发**。

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

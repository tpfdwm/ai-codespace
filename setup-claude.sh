#!/usr/bin/env bash
# 一键安装 Claude Code 并配好第三方 API，适合任何 Linux 终端
# （GitHub Codespaces / 阿里云 PAI-DSW / 魔搭 ModelScope / 腾讯 Cloud Studio 等）。
#
# 用法：
#   export ANTHROPIC_AUTH_TOKEN="你的第三方令牌"
#   bash setup-claude.sh
#
# 持久化（重要）：像 ModelScope / PAI-DSW 这类实例，只有数据盘 /mnt/workspace 重开后还在，
# 家目录和 ~/.bashrc 会被清空。这种平台请指定持久盘，一次装、以后只 source 一行即可：
#   export PERSIST_DIR=/mnt/workspace
#   export ANTHROPIC_AUTH_TOKEN="你的第三方令牌"
#   bash setup-claude.sh
#   # 以后每次重开：  source /mnt/workspace/start-claude.sh && claude
#
# 可选（不设则用默认值）：
#   export ANTHROPIC_BASE_URL="https://cc.freemodel.dev"
#   export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-8"
set -e

BASE_URL="${ANTHROPIC_BASE_URL:-https://cc.freemodel.dev}"
OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-4-8}"

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
  echo "❌ 请先设置令牌后再运行："
  echo '   export ANTHROPIC_AUTH_TOKEN="你的第三方令牌"'
  exit 1
fi

# 安装根目录：设了 PERSIST_DIR（如 /mnt/workspace）就装到持久盘，否则装到家目录
ROOT="${PERSIST_DIR:-$HOME/.local}"
NODE_DIR="$ROOT/node"
NPM_PREFIX="$ROOT/npm-global"
CFG_DIR="$ROOT/claude-config"
START="$ROOT/start-claude.sh"

mkdir -p "$ROOT"
echo "安装位置：$ROOT"

# 用国内 npm 镜像，装包更快（失败也不影响）
npm config set registry https://registry.npmmirror.com 2>/dev/null || true

# 1) 装 Node.js 到 $NODE_DIR（已存在则跳过）；用阿里云 npmmirror 预编译包，国内最稳
if [ ! -x "$NODE_DIR/bin/node" ]; then
  echo "安装 Node.js 到 $NODE_DIR …"
  NODE_VER="v20.18.0"
  curl -fsSL "https://registry.npmmirror.com/-/binary/node/${NODE_VER}/node-${NODE_VER}-linux-x64.tar.gz" -o /tmp/node.tar.gz
  mkdir -p "$NODE_DIR"
  tar -xzf /tmp/node.tar.gz -C "$NODE_DIR" --strip-components=1
fi
export PATH="$NODE_DIR/bin:$NPM_PREFIX/bin:$PATH"
echo "Node 版本：$(node -v)"

# 2) 全局安装 Claude Code 到 $NPM_PREFIX
npm config set prefix "$NPM_PREFIX"
npm install -g @anthropic-ai/claude-code

# 3) 写入 Claude Code 默认设置（放持久盘，启动脚本会拷到 ~/.claude）
mkdir -p "$CFG_DIR"
cat > "$CFG_DIR/settings.json" <<'JSON'
{
  "permissions": { "defaultMode": "bypassPermissions" },
  "skipDangerousModePermissionPrompt": true,
  "theme": "dark",
  "effortLevel": "xhigh"
}
JSON

# 4) 生成启动脚本：每次重开终端只需 source 它（不重装、瞬间完成）
cat > "$START" <<EOF
# 每次重开终端跑：source 这个脚本即可用 claude（文件都在 $ROOT，不重装）
export PATH="$NODE_DIR/bin:$NPM_PREFIX/bin:\$PATH"
export ANTHROPIC_BASE_URL="$BASE_URL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$OPUS_MODEL"
export ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
# root 容器（如 DSW/ModelScope）下允许 bypass 权限模式
export IS_SANDBOX=1
mkdir -p "\$HOME/.claude" && cp "$CFG_DIR/settings.json" "\$HOME/.claude/settings.json"
EOF

# 5) 家目录模式（未指定持久盘）：让新终端自动加载，省得手动 source
if [ "$ROOT" = "$HOME/.local" ]; then
  grep -q "start-claude.sh" "$HOME/.bashrc" 2>/dev/null || echo "source \"$START\"" >> "$HOME/.bashrc"
fi

echo ""
echo "✅ 安装完成。启动："
echo "   source $START && claude"
if [ "$ROOT" = "$HOME/.local" ]; then
  echo "   （家目录模式：新开终端会自动加载，直接 claude 也行）"
else
  echo "   （持久盘模式：以后每次重开实例，只跑上面这一行即可，无需重装）"
fi

#!/usr/bin/env bash
# switch_proj.sh
# 用法：bash switch_proj.sh

set -e   # 任何一步失败就立即退出

PROJ_DIR="ios/App/App.xcodeproj"
ORIG="${PROJ_DIR}/project.pbxproj"
BACK="${PROJ_DIR}/project2.pbxproj"
TEMP="${PROJ_DIR}/project1.pbxproj"

# 1. 备份原文件（如果存在）
if [[ -f "$ORIG" ]]; then
  mv "$ORIG" "$BACK"
fi

# 2. 把 project1.pbxproj 变成正式 project.pbxproj
if [[ -f "$TEMP" ]]; then
  mv "$TEMP" "$ORIG"
else
  echo "❌ 找不到 $TEMP，脚本终止"
  exit 1
fi

# 3. 执行 npx cap sync ios
echo "🔄 运行 npx cap sync ios ..."
npx cap sync ios

# 4. 还原文件名
echo "🔙 还原文件名 ..."
mv "$ORIG" "$TEMP"
if [[ -f "$BACK" ]]; then
  mv "$BACK" "$ORIG"
fi

echo "✅ 全部完成"
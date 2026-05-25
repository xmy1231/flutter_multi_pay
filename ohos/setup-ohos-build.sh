#!/bin/bash
# OHOS build setup
# Steps:
#   1. Ensure example/ohos/hvigorfile.ts has flutterHvigorPlugin registered (handles flutter.har at build time)
#   2. Run `ohpm install` in example/ohos/
#   3. source this script (patches Alipay SDK metadata for Hvigor bytecode HAR compatibility)
# Usage: source setup-ohos-build.sh

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

set -e

ALIPAY_PKG="@cashier_alipay+cashiersdk@15.8.43"
OH_MODULES_DIR="example/ohos/oh_modules/.ohpm"
PATCH_SCRIPT="ohos/patch-hvigor-ohmurl.js"

# Step 1: Apply byteCodeHar flag to Alipay SDK's cached metadata
CACHED_JSON="${OH_MODULES_DIR}/${ALIPAY_PKG}/oh_modules/@cashier_alipay/cashiersdk/oh-package.json5"
if [ -f "$CACHED_JSON" ]; then
    if grep -q '"byteCodeHar"' "$CACHED_JSON"; then
        echo "[setup] byteCodeHar already set in $CACHED_JSON"
    else
        # Insert byteCodeHar:true after the name line
        python3 -c "
import re
with open('$CACHED_JSON', 'r') as f:
    c = f.read()
c = c.replace('\"name\": \"@cashier_alipay/cashiersdk\",', '\"name\": \"@cashier_alipay/cashiersdk\",\n  \"byteCodeHar\": true,')
with open('$CACHED_JSON', 'w') as f:
    f.write(c)
"
        echo "[setup] Added byteCodeHar:true to $CACHED_JSON"
    fi
else
    echo "[setup] WARNING: Alipay SDK metadata not found at $CACHED_JSON"
    echo "[setup] Run 'ohpm install' first"
    exit 1
fi

echo "[setup] Done. Build from example/ directory:"
echo ""
echo "  cd example"
echo "  NODE_OPTIONS=\"--require ${PROJECT_ROOT}/${PATCH_SCRIPT}\" \\"
echo "    fvm flutter build hap --debug && \\"
echo "    node ${PROJECT_ROOT}/ohos/patch-loader-json.js"
echo ""

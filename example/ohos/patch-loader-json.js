const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.join(__dirname, '..');
const ALIPAY_PKG = '@cashier_alipay+cashiersdk@15.8.43';
const ALIPAY_ABC = path.join(
  PROJECT_ROOT, 'example', 'ohos', 'oh_modules', '.ohpm',
  ALIPAY_PKG, 'oh_modules', '@cashier_alipay', 'cashiersdk',
  'ets', 'modules.abc'
);
const PKG_NAME = '@cashier_alipay/cashiersdk';

function findLoaderJson() {
  const baseDir = path.join(PROJECT_ROOT, 'example', 'ohos', 'entry', 'build');
  if (!fs.existsSync(baseDir)) return null;
  const dirs = fs.readdirSync(baseDir);
  let candidates = [];
  for (const dir of dirs) {
    const loaderDir = path.join(baseDir, dir, 'intermediates', 'loader');
    if (!fs.existsSync(loaderDir)) continue;
    const configs = fs.readdirSync(loaderDir);
    for (const config of configs) {
      const loaderFile = path.join(loaderDir, config, 'loader.json');
      if (fs.existsSync(loaderFile)) {
        candidates.push({ path: loaderFile, mtime: fs.statSync(loaderFile).mtimeMs });
      }
    }
  }
  if (candidates.length === 0) return null;
  candidates.sort((a, b) => b.mtime - a.mtime);
  return candidates[0].path;
}

function patchByteCodeHarInfo() {
  if (!fs.existsSync(ALIPAY_ABC)) {
    console.error('[patch-loader-json] ERROR: Alipay ABC not found at', ALIPAY_ABC);
    process.exit(1);
  }

  const loaderJsonPath = findLoaderJson();
  if (!loaderJsonPath) {
    console.error('[patch-loader-json] ERROR: loader.json not found in build output');
    process.exit(1);
  }

  const raw = fs.readFileSync(loaderJsonPath, 'utf-8');
  const obj = JSON.parse(raw);

  obj.byteCodeHarInfo = obj.byteCodeHarInfo || {};
  if (!obj.byteCodeHarInfo[PKG_NAME]) {
    obj.byteCodeHarInfo[PKG_NAME] = {
      abcPath: ALIPAY_ABC,
      packageName: PKG_NAME
    };
    fs.writeFileSync(loaderJsonPath, JSON.stringify(obj, null, 2));
    console.log('[patch-loader-json] Injected byteCodeHarInfo for', PKG_NAME);
  } else {
    console.log('[patch-loader-json] byteCodeHarInfo already exists for', PKG_NAME);
  }

  // Also ensure ABC is in loader_out
  const loaderDir = path.dirname(loaderJsonPath);
  const lastLoader = loaderDir.lastIndexOf('loader');
  const parent = loaderDir.substring(0, lastLoader);
  const config = path.basename(loaderDir);
  const targetDir = path.join(parent, 'loader_out', config, 'ets');
  const targetFile = path.join(targetDir, '@cashier_alipay-cashiersdk.abc');
  if (!fs.existsSync(targetFile)) {
    fs.mkdirSync(targetDir, { recursive: true });
    fs.copyFileSync(ALIPAY_ABC, targetFile);
    console.log('[patch-loader-json] Copied ABC to', targetFile);
  } else {
    console.log('[patch-loader-json] ABC already exists at', targetFile);
  }
}

patchByteCodeHarInfo();

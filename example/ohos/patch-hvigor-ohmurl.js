const myFs = require('fs');
const myPath = require('path');

const PROJECT_ROOT = myPath.join(__dirname, '..');
const ALIPAY_ABC = myPath.join(PROJECT_ROOT, 'example', 'ohos', 'oh_modules', '.ohpm',
  '@cashier_alipay+cashiersdk@15.8.43', 'oh_modules', '@cashier_alipay', 'cashiersdk',
  'ets', 'modules.abc');
const ABC_TARGET_NAME = '@cashier_alipay-cashiersdk.abc';

try { myFs.writeFileSync('/tmp/patch-loaded.txt', 'loaded ' + Date.now() + '\n'); } catch(e) {}

// Inject strictMode schema for hvigorconfig.ts useNormalizedOHMUrl
const origJSONParse = JSON.parse;
JSON.parse = function(...args) {
  const result = origJSONParse.apply(this, args);
  if (result && typeof result === 'object' && !Array.isArray(result) &&
      result.definitions && result.definitions.buildOption) {
    const bo = result.definitions.buildOption;
    if (bo.propertyNames && Array.isArray(bo.propertyNames.enum) &&
        !bo.propertyNames.enum.includes('strictMode')) {
      bo.propertyNames.enum.push('strictMode');
      if (!bo.properties) bo.properties = {};
      if (!bo.properties.strictMode) {
        bo.properties.strictMode = {
          type: 'object',
          propertyNames: { enum: ['useNormalizedOHMUrl'] },
          properties: { useNormalizedOHMUrl: { type: 'boolean' } }
        };
      }
    }
  }
  return result;
};

// Copy Alipay .abc to .../loader_out/<config>/ets/
function ensureAlipayAbcInLoaderOut(loaderJsonPath) {
  try {
    const abcExists = myFs.existsSync(ALIPAY_ABC);
    if (!abcExists) {
      myFs.writeFileSync('/tmp/patch-copy-debug.txt', 'ALIPAY_ABC does not exist: ' + ALIPAY_ABC + '\n', { flag: 'a' });
      return;
    }
    const d = myPath.dirname(loaderJsonPath);
    const lastLoader = d.lastIndexOf('loader');
    const parent = d.substring(0, lastLoader);
    const config = myPath.basename(d);
    const targetDir = myPath.join(parent, 'loader_out', config, 'ets');
    const targetFile = myPath.join(targetDir, ABC_TARGET_NAME);
    const debugStr = 'd=' + d + '\nlastLoader=' + lastLoader + '\nparent=' + parent + '\nconfig=' + config + '\ntargetDir=' + targetDir + '\ntargetFile=' + targetFile + '\nfileExists=' + myFs.existsSync(targetFile) + '\n';
    myFs.writeFileSync('/tmp/patch-copy-debug.txt', debugStr, { flag: 'a' });
    if (!myFs.existsSync(targetFile)) {
      if (!myFs.existsSync(targetDir)) myFs.mkdirSync(targetDir, { recursive: true });
      myFs.copyFileSync(ALIPAY_ABC, targetFile);
      myFs.writeFileSync('/tmp/patch-copy-debug.txt', 'COPY DONE\n', { flag: 'a' });
    }
  } catch(e) {
    myFs.writeFileSync('/tmp/patch-copy-error.txt', String(e) + '\n' + (e.stack || '') + '\n', { flag: 'a' });
  }
}

// Patch byteCodeHarInfo with ABSOLUTE path so compiler can find it
function patchLoaderJson(data) {
  if (!data) return data;
  const str = typeof data === 'string' ? data : data.toString();
  let obj;
  try { obj = JSON.parse(str); } catch(e) { return data; }
  if (!obj || typeof obj !== 'object' || !('harNameOhmMap' in obj)) return data;
  const pkgName = '@cashier_alipay/cashiersdk';
  obj.byteCodeHarInfo = obj.byteCodeHarInfo || {};
  if (!obj.byteCodeHarInfo[pkgName]) {
    obj.byteCodeHarInfo[pkgName] = {
      abcPath: ALIPAY_ABC,  // absolute path for build system
      packageName: pkgName
    };
  }
  return JSON.stringify(obj, null, 2);
}

let callCount = 0;
function hookOnLoaderJson(path, data) {
  if (typeof path === 'string' && path.includes('loader.json')) {
    callCount++;
    try {
      ensureAlipayAbcInLoaderOut(path);
      return patchLoaderJson(data);
    } catch (e) {
      try { myFs.writeFileSync('/tmp/patch-error.txt', '#' + callCount + ': ' + String(e) + '\n', { flag: 'a' }); } catch (_) {}
    }
  }
  return data;
}

// --- Hook fs.writeFileSync ---
const origWriteFileSync = myFs.writeFileSync;
myFs.writeFileSync = function (path, data, options) {
  return origWriteFileSync.call(this, path, hookOnLoaderJson(path, data), options);
};

// --- Hook fs.writeFile (async) ---
const origWriteFile = myFs.writeFile;
myFs.writeFile = function (path, data, options, callback) {
  if (typeof options === 'function') { callback = options; options = undefined; }
  const patched = hookOnLoaderJson(path, data);
  if (callback) return origWriteFile.call(this, path, patched, options, callback);
  return origWriteFile.call(this, path, patched, options);
};

// --- Hook fs.promises.writeFile ---
if (myFs.promises) {
  const origPromisesWriteFile = myFs.promises.writeFile;
  myFs.promises.writeFile = function (path, data, options) {
    return origPromisesWriteFile.call(this, path, hookOnLoaderJson(path, data), options);
  };
}

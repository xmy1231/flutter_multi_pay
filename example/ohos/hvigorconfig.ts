import path from 'path'
import { injectNativeModules } from 'flutter-hvigor-plugin';

injectNativeModules(__dirname, path.dirname(__dirname))

export function getConfig() {
  return {
    useNormalizedOHMUrl: true
  }
}
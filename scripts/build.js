/**
 * Cross-platform build script for RoadEdge AI Web deployment on Vercel
 * Automatically detects or bootstraps the Flutter SDK, builds the Web target,
 * and verifies output assets for static CDN distribution.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..');
const FLUTTER_APP_DIR = fs.existsSync(path.join(ROOT_DIR, 'roadedge_ai'))
  ? path.join(ROOT_DIR, 'roadedge_ai')
  : ROOT_DIR;

console.log('🚀 [RoadEdge AI] Starting Vercel Web Build Pipeline...');
console.log(`📂 Project Root: ${ROOT_DIR}`);
console.log(`📂 Flutter App: ${FLUTTER_APP_DIR}`);

function run(cmd, cwd = ROOT_DIR) {
  return execSync(cmd, {
    stdio: 'inherit',
    cwd,
  });
}

// 1. Determine Flutter executable
function getFlutterCommand() {
  const binaryName = process.platform === 'win32' ? 'flutter.bat' : 'flutter';

  // Check if flutter is already available in PATH
  try {
    execSync(`${binaryName} --version`, { stdio: 'pipe' });
    console.log(`✅ Found existing Flutter installation in PATH (${binaryName}).`);
    return binaryName;
  } catch (_) {}

  // Check if previously downloaded in .flutter_sdk
  const localSdkBin = path.join(ROOT_DIR, '.flutter_sdk', 'bin');
  const localFlutterExec = path.join(localSdkBin, binaryName);
  if (fs.existsSync(localFlutterExec)) {
    console.log(`✅ Found cached Flutter SDK at ${localSdkBin}`);
    process.env.PATH = `${localSdkBin}${path.delimiter}${process.env.PATH}`;
    return localFlutterExec;
  }

  // If not found (e.g. standard Vercel cloud Linux builder), clone shallow Flutter SDK
  console.log('⚡ Flutter not found in build container. Bootstrapping Flutter stable SDK...');
  const sdkDir = path.join(ROOT_DIR, '.flutter_sdk');
  try {
    run(`git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${sdkDir}"`, ROOT_DIR);
    process.env.PATH = `${localSdkBin}${path.delimiter}${process.env.PATH}`;
    console.log('✅ Flutter SDK clone complete.');
    return localFlutterExec;
  } catch (err) {
    console.error('❌ Failed to download Flutter SDK:', err.message);
    process.exit(1);
  }
}

const flutterCmd = getFlutterCommand();

// 2. Display environment version info
try {
  console.log('\n--- Flutter Environment ---');
  run(`${flutterCmd} --version`);
} catch (e) {
  console.warn('⚠️ Could not fetch Flutter version details.');
}

// 3. Resolve dependencies
console.log('\n--- Resolving Flutter Dependencies ---');
run(`${flutterCmd} pub get`, FLUTTER_APP_DIR);

// 4. Build Flutter Web release
console.log('\n--- Building Flutter Web Release Bundle ---');
run(`${flutterCmd} build web --release --no-wasm-dry-run`, FLUTTER_APP_DIR);

// 5. Verify Build Output
const outputDir = path.join(FLUTTER_APP_DIR, 'build', 'web');
const indexHtml = path.join(outputDir, 'index.html');

if (fs.existsSync(indexHtml)) {
  console.log(`\n🎉 [RoadEdge AI] Build SUCCEEDED!`);
  console.log(`📦 Web artifacts ready at: ${outputDir}`);
  console.log(`🌐 Ready for Vercel global edge CDN distribution.`);
} else {
  console.error(`\n❌ [RoadEdge AI] Build verification failed: ${indexHtml} not found.`);
  process.exit(1);
}

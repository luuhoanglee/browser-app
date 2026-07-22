import { mkdir, writeFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';
import { remote } from 'webdriverio';

const rootDir = process.cwd();
const run = promisify(execFile);
const deviceName = process.env.APPIUM_DEVICE_NAME ?? 'Android Emulator';
const evidenceDir =
  process.env.EVIDENCE_DIR ??
  path.join(rootDir, 'docs', 'evidence', 'v1.0.2', 'split-view');
const apkPath =
  process.env.APK_PATH ??
  path.join(rootDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');

await mkdir(evidenceDir, { recursive: true });

const driver = await remote({
  hostname: process.env.APPIUM_HOST ?? '127.0.0.1',
  port: Number(process.env.APPIUM_PORT ?? 4723),
  path: process.env.APPIUM_PATH ?? '/wd/hub',
  logLevel: 'info',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': deviceName,
    'appium:app': apkPath,
    'appium:appPackage': 'com.dino.pardix',
    'appium:fullReset': true,
    'appium:enforceAppInstall': true,
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 120
  }
});

async function tapByAccessibilityId(label, timeout = 15000) {
  const element = await driver.$(`~${label}`);
  await element.waitForDisplayed({ timeout });
  await element.click();
}

async function tapBottomTabs() {
  const rect = await driver.getWindowRect();
  await driver.performActions([
    {
      type: 'pointer',
      id: 'finger1',
      parameters: { pointerType: 'touch' },
      actions: [
        {
          type: 'pointerMove',
          duration: 0,
          x: Math.round(rect.width * 0.94),
          y: Math.round(rect.height * 0.95)
        },
        { type: 'pointerDown', button: 0 },
        { type: 'pause', duration: 80 },
        { type: 'pointerUp', button: 0 }
      ]
    }
  ]);
  await driver.releaseActions();
}

async function tapTabs() {
  try {
    await tapByAccessibilityId('Tabs', 3000);
  } catch {
    await tapBottomTabs();
  }
}

async function tapAtRatio(xRatio, yRatio) {
  const rect = await driver.getWindowRect();
  await driver.performActions([
    {
      type: 'pointer',
      id: 'finger1',
      parameters: { pointerType: 'touch' },
      actions: [
        {
          type: 'pointerMove',
          duration: 0,
          x: Math.round(rect.width * xRatio),
          y: Math.round(rect.height * yRatio)
        },
        { type: 'pointerDown', button: 0 },
        { type: 'pause', duration: 80 },
        { type: 'pointerUp', button: 0 }
      ]
    }
  ]);
  await driver.releaseActions();
}

async function tapAddTab() {
  try {
    await tapByAccessibilityId('Add tab', 3000);
  } catch {
    await tapAtRatio(0.92, 0.36);
  }
}

async function tapEnableSplitView() {
  try {
    await tapByAccessibilityId('Enable split view', 3000);
  } catch {
    await tapAtRatio(0.72, 0.36);
  }
}

async function tapFirstCardSplitAction() {
  try {
    await tapByAccessibilityId('Use tab in split view', 3000);
  } catch {
    await tapAtRatio(0.44, 0.48);
  }
}

async function drag(startX, startY, endX, endY) {
  await driver.execute('mobile: dragGesture', {
    startX,
    startY,
    endX,
    endY,
    speed: 1200
  });
}

async function rotateWithAdb(rotation) {
  if (!process.env.APPIUM_DEVICE_NAME) {
    await driver.setOrientation(rotation === 1 ? 'LANDSCAPE' : 'PORTRAIT');
    return;
  }

  await run('adb', [
    '-s',
    deviceName,
    'shell',
    'settings',
    'put',
    'system',
    'accelerometer_rotation',
    '0'
  ]);
  await run('adb', [
    '-s',
    deviceName,
    'shell',
    'settings',
    'put',
    'system',
    'user_rotation',
    String(rotation)
  ]);
}

try {
  await driver.activateApp('com.dino.pardix');
  await driver.pause(700);

  await tapTabs();
  await tapAddTab();

  await tapTabs();
  await driver.saveScreenshot(path.join(evidenceDir, '00-before-split.png'));
  await writeFile(
    path.join(evidenceDir, '00-before-split.xml'),
    await driver.getPageSource()
  );
  await tapFirstCardSplitAction();
  await driver.pause(500);
  await driver.saveScreenshot(path.join(evidenceDir, '00-after-split.png'));
  await driver.back();
  await driver.pause(700);

  await driver.saveScreenshot(path.join(evidenceDir, '01-split-portrait.png'));

  const portrait = await driver.getWindowRect();
  await drag(
    Math.round(portrait.width / 2),
    Math.round(portrait.height * 0.38),
    Math.round(portrait.width / 2),
    Math.round(portrait.height * 0.52)
  );
  await driver.pause(500);
  await driver.saveScreenshot(
    path.join(evidenceDir, '02-split-portrait-resized.png')
  );

  if (process.env.SKIP_LANDSCAPE !== '1') {
    await rotateWithAdb(1);
    await driver.pause(1200);
    await driver.saveScreenshot(
      path.join(evidenceDir, '03-split-landscape.png')
    );
  }
} catch (error) {
  await driver.saveScreenshot(path.join(evidenceDir, '99-failure.png'));
  throw error;
} finally {
  await driver.deleteSession();
}

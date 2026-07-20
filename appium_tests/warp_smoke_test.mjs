import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { remote } from 'webdriverio';

const rootDir = process.cwd();
const evidenceDir = path.join(rootDir, 'docs', 'evidence', 'v1.0.1');
const apkPath =
  process.env.APK_PATH ??
  path.join(rootDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');

await mkdir(evidenceDir, { recursive: true });

const driver = await remote({
  hostname: process.env.APPIUM_HOST ?? '127.0.0.1',
  port: Number(process.env.APPIUM_PORT ?? 4723),
  path: process.env.APPIUM_PATH ?? '/wd/hub',
  logLevel: 'info',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': process.env.APPIUM_DEVICE_NAME ?? 'Android Emulator',
    'appium:app': apkPath,
    'appium:appPackage': 'com.dino.pardix',
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 120
  }
});

try {
  const warpButton = await driver.$('~WARP / 1.1.1.1');
  await warpButton.waitForDisplayed({ timeout: 15000 });
  await driver.saveScreenshot(path.join(evidenceDir, '01-home.png'));
  await warpButton.click();

  await driver.pause(1500);
  await driver.saveScreenshot(path.join(evidenceDir, '02-warp-sheet.png'));
} catch (error) {
  await driver.saveScreenshot(path.join(evidenceDir, '99-failure.png'));
  throw error;
} finally {
  await driver.deleteSession();
}

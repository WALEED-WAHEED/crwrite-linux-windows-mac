require('dotenv').config();
const { execSync } = require('child_process');
const path = require('path');
const { notarize } = require('@electron/notarize');

function isAppSigned(appPath) {
  try {
    execSync(`codesign -dv --verbose=2 "${appPath}" 2>&1`, { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
}

exports.default = async function notarizing(context) {
  const { electronPlatformName, appOutDir } = context;
  if (electronPlatformName !== 'darwin') {
    return;
  }

  const appName = context.packager.appInfo.productFilename;
  const appPath = path.join(appOutDir, `${appName}.app`);

  if (!isAppSigned(appPath)) {
    console.log('Notarization skipped: app is not code-signed (no Developer ID certificate). DMG/zip will be produced but the app is unsigned.');
    return;
  }

  if (!process.env.APPLEID || !process.env.APPLEIDPASS || !process.env.TEAMID) {
    console.log('Notarization skipped: APPLEID, APPLEIDPASS, and TEAMID must be set to notarize.');
    return;
  }

  try {
    await notarize({
      appBundleId: 'org.coastrunner.crwrite',
      appPath,
      appleId: process.env.APPLEID,
      appleIdPassword: process.env.APPLEIDPASS,
      teamId: process.env.TEAMID,
    });
    console.log('Notarization successful');
  } catch (error) {
    console.error('Notarization failed:', error);
    throw error;
  }
};

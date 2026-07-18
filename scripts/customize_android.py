#!/usr/bin/env python3
"""Customize the Flutter-generated Android project for Gold Signal AI.
Run after `flutter create` to add AdMob, notifications, and minSdk changes."""

import re
import xml.dom.minidom

# 1. Patch build.gradle — minSdkVersion 23 (required by google_mobile_ads)
with open('android/app/build.gradle', 'r') as f:
    gradle = f.read()

gradle = gradle.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 23')
gradle = gradle.replace('signingConfig signingConfigs.release', 'signingConfig signingConfigs.debug')

with open('android/app/build.gradle', 'w') as f:
    f.write(gradle)
print("Patched build.gradle: minSdkVersion=23, debug signing")

# 2. Patch AndroidManifest.xml — add permissions, AdMob, notifications
with open('android/app/src/main/AndroidManifest.xml', 'r') as f:
    manifest = f.read()

# Add permissions before <application
permissions = (
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n'
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n'
    '    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />\n'
    '    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />\n'
    '\n'
)
manifest = manifest.replace('<application', permissions + '<application')

# Add AdMob App ID meta-data right after <application ...> opening tag
manifest = re.sub(
    r'(<application[^>]*>)',
    r'\1\n        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" '
    r'android:value="ca-app-pub-3940256099942544~3347511713" />',
    manifest
)

# Add notification service and receiver after </activity>
notif = (
    '        <service android:name="com.dexterous.flutterlocalnotifications.ForegroundService" '
    'android:exported="false" android:stopWithTask="true" />\n'
    '        <receiver android:exported="false" '
    'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />'
)
manifest = manifest.replace('</activity>', '</activity>\n' + notif)

with open('android/app/src/main/AndroidManifest.xml', 'w') as f:
    f.write(manifest)
print("Patched AndroidManifest.xml: permissions, AdMob, notifications")

# 3. Validate XML
try:
    xml.dom.minidom.parse('android/app/src/main/AndroidManifest.xml')
    print("XML validation: PASSED")
except Exception as e:
    print(f"XML validation FAILED: {e}")
    raise

print("All Android customizations applied successfully.")

# SubsyWidget (iOS WidgetKit) — manual Xcode wiring

These source files are scaffolded by the spec-kit flow but the **Xcode target and
capabilities must be added in Xcode** (the `project.pbxproj` wiring is not
scripted). Do this once on a Mac with Xcode, then verify on a device/simulator.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File ▸ New ▸ Target… ▸ Widget Extension** → name it `SubsyWidget`
   (uncheck "Include Live Activity"). Let Xcode create the target.
3. Replace the generated files with the ones here (`SubsyWidget.swift`,
   `Info.plist`) — `kind` must stay `"SubsyWidget"` (matches `kIosWidgetName`).
4. **App Groups** capability on **both** the `Runner` target and the
   `SubsyWidget` target → add `group.com.halilergul.subsy`
   (use `Runner.entitlements` / `SubsyWidget.entitlements`).
5. Ensure the widget extension's Deployment Target is iOS 14+.
6. Run on a device/simulator; add the Subsy widget to the home screen.

The Flutter side already:
- calls `HomeWidget.setAppGroupId('group.com.halilergul.subsy')` at boot,
- writes the display keys + `HomeWidget.updateWidget(iOSName: 'SubsyWidget')`.

Android needs no manual step — the `<receiver>` is in `AndroidManifest.xml`.

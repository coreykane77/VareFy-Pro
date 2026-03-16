# VeraFy Prototype — Memory

## Project
- App renamed from ANKR Hire Prototype → **VeraFy**
- Xcode project: `ANKR Prototype -Hire/VeraFy.xcodeproj`
- Swift source folder: `ANKR Prototype -Hire/VeraFy Hire/`
- Uses `PBXFileSystemSynchronizedRootGroup` — new files added to the folder are auto-included in the build (no pbxproj edits needed)
- Target: iOS 26.2 / Xcode 26.2 / Swift 6.2
- Bundle ID: `com.verafy.app`
- Display name: `VeraFy` (set via `INFOPLIST_KEY_CFBundleDisplayName`)
- Key build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`

## Architecture
- MVVM with `@Observable` (not ObservableObject)
- ViewModels injected via `.environment()` from app root
- Navigation: `NavigationStack` with `NavRoute` enum + `navigationDestination`
- No persistence, no backend, all session state

## Key Files
- App entry: `VeraFy Hire/VeraFyApp.swift` — injects 5 VMs, sets `preferredColorScheme`
- Navigation enum: `Core/Navigation/NavRoute.swift`
- State machine: `ViewModels/WorkOrderViewModel.swift` — all integrity rules here
- Main hub: `Core/Home/HireHomeView.swift`
- Color palette: `Utilities/Extensions.swift` — verafyCyan, verafyDark, verafyCard, verafyGold

## Design Colors (renamed from ankr* → verafy*)
- verafyCyan: `Color(red: 0.05, green: 0.78, blue: 0.87)`
- verafyGold: `Color(red: 0.94, green: 0.75, blue: 0.04)` (used for "Offline" text)
- verafyDark: background `Color(red: 0.08, green: 0.08, blue: 0.08)`
- verafyCard: card bg `Color(red: 0.13, green: 0.13, blue: 0.13)`

## App Icon
- AppIcon.appiconset/AppIcon.png — replaced with VeraFy green V+F logo
- VareFy.imageset/VareFy.PNG — source icon asset (green V+F on dark green)

## Status
- Full scaffold built: 52 Swift files across Models, ViewModels, Services, Components, Core, Features
- All integrity gates implemented (photo count, status checks)
- Auto-pause (10s radius countdown) implemented with Swift async Task
- Navigation flows: PreWork→ActiveBilling and PostWork→Summary auto-navigate
- CLAUDE.md includes App Store Review — Demo Build Guidelines section
- Reference PNG screenshots in `/Users/coreykane/develop/ANKR Proto/` for other screens

## Reference PNGs available
- Main Page.png — home map ✓ implemented
- Main Stack.png, Wallet.png, Manage.png, Profile.png, Hire Prof.png, Boss Analytics.png, Payments.png

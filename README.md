# LCARS Calendar

```
STARFLEET FACILITIES COMMAND — PERSONAL SCHEDULING DIVISION
MEMORANDUM · STARDATE 48715.4
SUBJECT: WALL-MOUNTED FAMILY CALENDAR — LCARS INTERFACE MODULE
CLASSIFICATION: UNCLASSIFIED — OPEN SOURCE
```

**STATUS: PHASE 1 COMPLETE** · iPadOS · XcodeGen · SwiftUI

---

A native SwiftUI iPad calendar designed to run unattended on a wall or fridge mount. LCARS-themed to match the broader Mac Studio design system — elbow sidebar, header bar, month grid, agenda panel, footer bar. Reads from two Google Calendars (family members) via OAuth. Locked to landscape orientation.

## MISSION STATUS

| Phase | Status | Description |
|---|---|---|
| Phase 1 | ✅ Complete | Static shell — full LCARS layout with mock data, builds and runs on device |
| Phase 2 | Pending | Google Sign-In (SPM), OAuth, live `calendarList` + `events.list` API calls |
| Phase 3 | Pending | Dual-calendar support (two Google accounts) |
| Phase 4 | Pending | Kiosk hardening — always-on, auto-restart, screen-wake schedule |

## ARCHITECTURE

| Layer | Files |
|---|---|
| App entry | `LCARSCalendarApp.swift` |
| Theme | `Theme.swift` — LCARS color palette, layout constants, `Color(hex:)`, text style modifiers |
| Models | `Models/CalendarEvent.swift`, `Models/CalendarSource.swift` (calendar → color/label mapping) |
| Mock data | `Services/MockEventProvider.swift` — deterministic sparse events, no auth needed |
| State | `ViewModels/CalendarViewModel.swift` — displayed month, navigation, grid-day generation, agenda query |
| UI | `Views/RootView.swift`, `ElbowSidebarView`, `HeaderBarView`, `MonthGridView`, `AgendaPanelView`, `FooterBarView` |

## BUILD INSTRUCTIONS

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
git clone https://github.com/jsmith-obrien/lcars-calendar
cd lcars-calendar
xcodegen generate
open LCARSCalendar.xcodeproj
# ⌘R onto a simulator or iPad
```

Simulator build without signing:

```bash
xcodebuild \
  -project LCARSCalendar.xcodeproj \
  -scheme LCARSCalendar \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Deployment target: iOS 15.0.

## TECH STACK

Swift · SwiftUI · XcodeGen · Google Sign-In SDK · iOS 15+

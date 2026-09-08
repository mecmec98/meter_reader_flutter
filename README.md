# DapCWD Meter Reader

A Flutter mobile application for the **Dapitan City Water District (DapCWD)** that lets field meter readers record water meter readings, compute bills, and print billing statements via Bluetooth thermal printers.

The app is compatible with the legacy **LWUA BCWIN/MRDBA** system and works with the `MRADB.dbi` SQLite database format.

---

## Features

- **Post Meter Reading** — Browse and search consumer records, enter new meter readings, and see bill calculations update live using DapCWD tiered rate tables
- **Edit Meter Reading** — Modify previously saved readings and recalculate bills
- **Print Bill** — Send billing statements to Bluetooth thermal printers using ESC/POS commands
- **Database Management** — Import/export databases manually via the file picker, or transfer wirelessly via HTTP to a companion server
- **Reading Progress** — Track completed versus remaining readings directly on the home screen
- **Consumer Notes** — Attach field notes to consumer accounts
- **PIN-Protected Settings** — Secured app configuration access

---

## Tech Stack

- **Framework:** Flutter ^3.6.1
- **State Management:** Provider (`ChangeNotifier`)
- **Database:** SQLite via `sqflite`
- **Bluetooth Printing:** `blue_thermal_printer` (vendored local package) + `esc_pos_utils_plus`
- **Networking:** `http` (wireless database transfer)
- **File Handling:** `file_picker`, `path_provider`
- **Utilities:** `intl`, `image`, `image_picker`
- **Icons/Assets:** `flutter_svg`
- **Messaging:** `flutter_sms`

---

## Project Structure

```
lib/
├── main.dart                              # App entry point, route definitions
├── helpers/
│   ├── database_helper.dart               # MRADB.dbi SQLite operations
│   ├── appsettings_helper.dart            # App preferences/settings
│   ├── blueprinter_helper.dart            # Bluetooth printer integration
│   ├── calculatebill_helper.dart          # Bill computation logic
│   └── notes_helper.dart                  # Consumer notes handling
├── models/
│   ├── consumer_note_model.dart
│   ├── consumercard_model.dart
│   ├── databaselog_model.dart
│   ├── editlist_model.dart
│   ├── features_model.dart
│   ├── postmeterlist_model.dart
│   ├── prefs_model.dart
│   ├── printlist_model.dart
│   └── serversettings_model.dart
├── pages/
│   ├── home.dart                          # Reading progress dashboard
│   ├── postmeterreading.dart              # New meter reading entry
│   ├── editbilllist.dart                  # Edit saved readings
│   ├── printbilllist.dart                 # Bill printing queue
│   ├── databasepage.dart                  # Database import/export
│   ├── appsettingspage.dart               # Settings
│   ├── notes.dart                         # Notes management
│   ├── consumer_note_details.dart
│   ├── consumercard.dart                  # Consumer detail view
│   ├── databasedrawer.dart
│   ├── databasepage/
│   │   ├── currentreadinginfo.dart
│   │   ├── manualtransfer.dart
│   │   └── wirelesstransfer.dart
│   └── consumercard/
│       ├── bottom_buttons.dart
│       ├── consumer_info_card.dart
│       ├── particulars_container.dart
│       └── readers_field.dart
└── widgets/
    ├── pin_dialog.dart
    └── printerfab_widget.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.6.1`
- Android Studio or VS Code with Flutter extensions
- Android device/emulator with Bluetooth support for printing

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd meter_reader_flutter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Database

The app expects an `MRADB.dbi` SQLite database in the app's documents directory.

You can import one via:
- **Manual transfer** — file picker
- **Wireless transfer** — HTTP to a companion server

The database schema is compatible with the legacy LWUA BCWIN/MRDBA system.

---

## Building

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

---

## Notes

- The `blue_thermal_printer` package is vendored locally under `local_packages/`.
- Splash screen and launcher icons are configured in `pubspec.yaml` via `flutter_native_splash` and `flutter_launcher_icons`.

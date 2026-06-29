# DapCWD Meter Reader

A Flutter mobile application for the Dapitan City Water District (DapCWD) used by meter readers to record water meter readings, calculate bills, and print billing statements via Bluetooth thermal printers.

The app is compatible with the legacy LWUA BCWIN/MRDBA system and uses the `MRADB.dbi` SQLite database format.

## Features

- **Post Meter Reading** — View and search consumer records, input new meter readings with real-time bill calculation based on tiered rate tables
- **Edit Meter Reading** — Modify previously saved readings
- **Print Bill** — Print billing statements via Bluetooth thermal printers (ESC/POS)
- **Database Management** — Import/export databases manually via file picker or wirelessly via HTTP to a companion server
- **Reading Progress** — Track completed vs. remaining readings on the home screen
- **PIN-Protected Settings** — Secure access to app configuration

## Tech Stack

- **State Management:** Provider (ChangeNotifier)
- **Database:** SQLite via sqflite
- **Bluetooth Printing:** blue_thermal_printer (vendored local package) + esc_pos_utils_plus
- **Icons:** flutter_svg (SVG assets)
- **File Handling:** file_picker, path_provider
- **Networking:** http (wireless database transfer)
- **Image Processing:** image, image_picker

## Project Structure

```
lib/
├── main.dart                  # App entry point, route definitions
├── helpers/                   # Business logic & utilities
│   ├── database_helper.dart   # Main MRADB.dbi database operations
│   ├── appsettings_helper.dart
│   ├── blueprinter_helper.dart
│   └── calculatebill_helper.dart
├── models/                    # Data models
├── pages/                     # Screen views
│   ├── home.dart
│   ├── postmeterreading.dart
│   ├── consumercard.dart
│   ├── editbilllist.dart
│   ├── printbilllist.dart
│   ├── databasepage.dart
│   └── appsettingspage.dart
└── widgets/                   # Reusable widgets
    ├── pin_dialog.dart
    └── printerfab_widget.dart
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.6.1
- Android Studio or VS Code with Flutter extensions
- Android device/emulator with Bluetooth support

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

### Database

The app expects an `MRADB.dbi` SQLite database in the app's documents directory. You can import one via the Database screen (manual file picker or wireless transfer from a companion server).

## Building

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

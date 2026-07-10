# Trash

Files/symbols moved here during the 2026-07-11 directory cleanup because grepping
`lib/` found zero real usages. Nothing is deleted yet — review each item and
delete the file (or the whole `trash/` folder) once you're sure it's safe.

This folder is outside `lib/`, so it is **not** compiled into the app and is
excluded from `flutter analyze` (see `analysis_options.yaml`).

## Contents

- **kosong_page.dart** — `KosongPage` widget. Never routed in
  `core/router/router.dart`, never referenced from `main.dart`. Contains
  hardcoded strings from an earlier campus/e-konsul template
  ("E-Konsul PNL", "Login Sebagai Dosen/Mahasiswa") unrelated to this POS app.

- **barcode_scanner_screen.dart** — `BarcodeScannerScreen` widget wrapping
  `mobile_scanner`. No file under `lib/` imports it.

- **unused_components.dart** — 12 widgets/functions extracted from
  `lib/Configuration/components.dart` (now merged into `lib/core/widgets/`):
  `MyAppBar`, `MyDrawer`, `myDrawerItem`, `myTextField`, `mySelectField`,
  `myInputFile`, `mySelectDate`, `mySelectTime`, `MyButtonSecondary`,
  `MyLoading`, `MyDivider`, `MyNetworkImage`. None had any references outside
  the original file (`MyAppBar` was only used by the also-dead `kosong_page.dart`).

- **unused_configuration_extras.dart** — `HexColor`, extracted from
  `lib/Configuration/configuration.dart`. Unused anywhere in `lib/`.

## Kept (for reference — not in this folder)

These symbols from the same files *were* actually used and were migrated to
`lib/core/` instead of being trashed: `Warna` → `core/theme/colors.dart`;
`PopController`/`PopEffect` → `core/widgets/pop_effect.dart`;
`MyButtonPrimary`/`myButtonStyle` → `core/widgets/app_button.dart`;
`mySnackBar`/`ToastStatus` → `core/widgets/app_snackbar.dart`.

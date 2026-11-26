# Copia locale di image_picker_ios 0.8.13+16

Unica modifica: in `ImagePickerPlugin.swift`, `launchPHPicker`, con la scelta
multipla si imposta `config.selection = .ordered` (iOS 15+). La galleria di
iPhone mostra così il numero 1, 2, 3… su ogni foto toccata e restituisce le
foto in quell'ordine.

Collegata da `dependency_overrides` in `pubspec.yaml`. Licenza originale in
`LICENSE` (BSD, Flutter Authors).

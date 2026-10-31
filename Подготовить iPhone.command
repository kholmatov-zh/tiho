#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
TIHO_FLUTTER_BIN="$(command -v flutter || true)"
if [[ -z "$TIHO_FLUTTER_BIN" ]]; then
  TIHO_FLUTTER_BIN="$HOME/fl_sdk/flutter/bin/flutter"
fi
if [[ ! -x "$TIHO_FLUTTER_BIN" ]]; then
  print 'Не найден Flutter. Добавьте flutter/bin в PATH.'
  read '?Нажмите Enter для закрытия.'
  exit 1
fi
if ! xcodebuild -checkFirstLaunchStatus; then
  print 'Откройте Xcode и завершите первоначальную установку компонентов.'
  open -a /Applications/Xcode.app
  read '?Затем запустите этот файл снова. Нажмите Enter.'
  exit 1
fi
print 'Скачиваем iOS-файлы Flutter. Это требуется только при первом запуске.'
"$TIHO_FLUTTER_BIN" precache --ios
"$TIHO_FLUTTER_BIN" pub get
"$TIHO_FLUTTER_BIN" build ios --release --config-only --no-codesign
open -a /Applications/Xcode.app ios/Runner.xcworkspace
print '\nПроект открыт в Xcode.'
print '1. Runner → Signing & Capabilities → Team → ваш Personal Team.'
print '2. Выберите подключённый iPhone в верхней панели.'
print '3. Нажмите ▶ Run: схема Runner настроена на Release без отладчика.'
print 'После установки приложение можно открывать с иконки без Xcode.'
print 'Если потребуется: iPhone → Настройки → Конфиденциальность и безопасность → Режим разработчика.'
read '?Нажмите Enter, чтобы закрыть это окно.'
